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
        response.sendRedirect("dashboard.jsp");
        return;
    }

    int groupId = Integer.parseInt(groupIdStr);

    // ── POST: process the leave ───────────────────────────────────────────────
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

            PreparedStatement roleCheck = conn.prepareStatement(
                "SELECT membership_role FROM Membership WHERE user_id = ? AND group_id = ?");
            roleCheck.setInt(1, userId);
            roleCheck.setInt(2, groupId);
            ResultSet rs = roleCheck.executeQuery();

            if (rs.next() && "Leader".equals(rs.getString("membership_role"))) {
                session.setAttribute("flashError", "Leaders cannot leave. Delete the group instead.");
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Membership WHERE user_id = ? AND group_id = ?");
                ps.setInt(1, userId);
                ps.setInt(2, groupId);
                ps.executeUpdate();
            }
            conn.close();
        } catch (Exception e) {
            session.setAttribute("flashError", e.getMessage());
        }
        response.sendRedirect("dashboard.jsp");
        return;
    }

    // ── GET: load group name and show confirmation page ───────────────────────
    String groupName = "";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");
        PreparedStatement ps = conn.prepareStatement(
            "SELECT group_name FROM Study_Group WHERE group_id = ?");
        ps.setInt(1, groupId);
        ResultSet rs = ps.executeQuery();
        if (rs.next()) groupName = rs.getString("group_name");
        conn.close();
    } catch (Exception e) {
        response.sendRedirect("dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Leave Group – StudyMatch</title>
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
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:420px;margin-top:4rem;">
        <div class="sm-dashboard-side sm-quick-card" style="text-align:center;">

            <div style="font-size:2.2rem;margin-bottom:0.75rem;">🚪</div>
            <h2 style="margin:0 0 0.5rem;">Leave group?</h2>
            <p style="color:var(--sm-text-muted);font-size:0.95rem;margin:0 0 1.75rem;">
                You're about to leave <strong style="color:var(--sm-text);"><%= groupName %></strong>.
                You'll need to rejoin to access it again.
            </p>

            <div style="display:flex;gap:0.75rem;justify-content:center;">
                <form method="post" action="leaveGroup.jsp?groupId=<%= groupId %>">
                    <button type="submit"
                            style="background:#dc2626;color:#fff;border:none;cursor:pointer;
                                   padding:0.55rem 1.4rem;border-radius:var(--sm-radius-full,99px);
                                   font-size:0.95rem;font-weight:600;transition:background 0.15s;"
                            onmouseover="this.style.background='#b91c1c'"
                            onmouseout="this.style.background='#dc2626'">
                        Yes, leave
                    </button>
                </form>
                <a href="groupDetail.jsp?groupId=<%= groupId %>"
                   class="sm-btn sm-btn-outline"
                   style="padding:0.55rem 1.4rem;font-size:0.95rem;">
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
