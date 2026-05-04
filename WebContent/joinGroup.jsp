<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (int) session.getAttribute("userId");
    String groupIdStr = request.getParameter("groupId");

    if (groupIdStr == null || groupIdStr.isEmpty()) {
        response.sendRedirect("searchGroups.jsp");
        return;
    }

    int groupId = Integer.parseInt(groupIdStr);

    // ── Load group info ───────────────────────────────────────────────────────
    String groupName = "", groupStatus = "", storedPasscode = "";
    int maxCapacity = 0, currentMembers = 0;
    boolean alreadyMember = false;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        PreparedStatement ps = conn.prepareStatement(
            "SELECT sg.group_name, sg.current_status, sg.passcode, sg.max_capacity, " +
            "COUNT(m.user_id) AS current_members " +
            "FROM Study_Group sg LEFT JOIN Membership m ON sg.group_id = m.group_id " +
            "AND m.membership_status = 'Active' " +
            "WHERE sg.group_id = ? GROUP BY sg.group_id");
        ps.setInt(1, groupId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) {
            groupName       = rs.getString("group_name");
            groupStatus     = rs.getString("current_status");
            storedPasscode  = rs.getString("passcode") != null ? rs.getString("passcode") : "";
            maxCapacity     = rs.getInt("max_capacity");
            currentMembers  = rs.getInt("current_members");
        }
        ps.close();

        ps = conn.prepareStatement(
            "SELECT 1 FROM Membership WHERE user_id = ? AND group_id = ? AND membership_status = 'Active'");
        ps.setInt(1, userId);
        ps.setInt(2, groupId);
        rs = ps.executeQuery();
        alreadyMember = rs.next();
        ps.close();
        conn.close();
    } catch (Exception e) {
        session.setAttribute("flashError", e.getMessage());
        response.sendRedirect("searchGroups.jsp");
        return;
    }

    if (alreadyMember) {
        response.sendRedirect("groupDetail.jsp?groupId=" + groupId);
        return;
    }

    if (currentMembers >= maxCapacity) {
        session.setAttribute("flashError", "Group is full.");
        response.sendRedirect("searchGroups.jsp");
        return;
    }

    // ── Public group on GET: join immediately ─────────────────────────────────
    if ("Public".equals(groupStatus) && "GET".equalsIgnoreCase(request.getMethod())) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Membership (user_id, group_id, joined_at, membership_role, membership_status) " +
                "VALUES (?, ?, NOW(), 'Member', 'Active')");
            ps.setInt(1, userId);
            ps.setInt(2, groupId);
            ps.executeUpdate();
            conn.close();
        } catch (Exception e) {
            session.setAttribute("flashError", e.getMessage());
            response.sendRedirect("searchGroups.jsp");
            return;
        }
        response.sendRedirect("groupDetail.jsp?groupId=" + groupId);
        return;
    }

    // ── Private group POST: verify passcode then join ─────────────────────────
    String passcodeError = null;
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String entered = request.getParameter("passcode");
        if (entered != null && entered.trim().equals(storedPasscode)) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Membership (user_id, group_id, joined_at, membership_role, membership_status) " +
                    "VALUES (?, ?, NOW(), 'Member', 'Active')");
                ps.setInt(1, userId);
                ps.setInt(2, groupId);
                ps.executeUpdate();
                conn.close();
                response.sendRedirect("groupDetail.jsp?groupId=" + groupId);
                return;
            } catch (Exception e) {
                passcodeError = "Database error: " + e.getMessage();
            }
        } else {
            passcodeError = "Incorrect passcode. Please try again.";
        }
    }
    // Falls through to render the passcode form (private group GET or failed POST)
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Join <%= groupName %> – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="dashboard.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
            <span>course-based study groups</span>
        </a>
        <nav class="sm-nav">
            <a href="searchGroups.jsp" class="sm-btn sm-btn-outline">← Back to Search</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:420px;margin-top:3.5rem;">
        <div class="sm-dashboard-side sm-quick-card" style="text-align:center;">

            <div style="font-size:2.2rem;margin-bottom:0.6rem;">🔒</div>
            <div class="sm-small-label" style="margin-bottom:0.2rem;">Private Group</div>
            <h2 style="margin:0 0 0.5rem;"><%= groupName %></h2>
            <p style="color:var(--sm-text-muted);font-size:0.9rem;margin:0 0 1.25rem;">
                This group requires a passcode to join.
            </p>

            <% if (passcodeError != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;
                            padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.9rem;text-align:left;">
                    <%= passcodeError %>
                </div>
            <% } %>

            <form method="post" action="joinGroup.jsp?groupId=<%= groupId %>"
                  style="display:flex;flex-direction:column;gap:0.75rem;text-align:left;">
                <div class="sm-field-group">
                    <label for="passcode">Passcode</label>
                    <input id="passcode" class="sm-input" type="password" name="passcode"
                           placeholder="Enter group passcode" required autofocus>
                </div>
                <button type="submit" class="sm-btn sm-btn-primary sm-full-width">
                    Join Group
                </button>
            </form>

            <div style="margin-top:1rem;">
                <a href="searchGroups.jsp"
                   style="font-size:0.85rem;color:var(--sm-text-muted);text-decoration:none;">
                    Cancel
                </a>
            </div>

        </div>
    </div>
</main>

<footer class="sm-footer">
    <div class="sm-container sm-footer-content">
        <span>© <%= java.time.Year.now() %> StudyMatch</span>
        <span>Built for collaborative learning in higher education.</span>
    </div>
</footer>

</body>
</html>
