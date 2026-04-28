<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");
    int userId = (Integer) session.getAttribute("userId");
    String error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch", "root", "mysql@1234");
            conn.setAutoCommit(false);

            // Delete replies on messages in groups this user leads
            PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM Reply WHERE message_id IN " +
                "(SELECT message_id FROM Message WHERE group_id IN " +
                "(SELECT group_id FROM Study_Group WHERE leader_id = ?))"
            );
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete group tags for groups this user leads
            ps = conn.prepareStatement("DELETE FROM Group_Tag WHERE group_id IN (SELECT group_id FROM Study_Group WHERE leader_id = ?)");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete meeting schedules for groups this user leads
            ps = conn.prepareStatement("DELETE FROM Meeting_Schedule WHERE group_id IN (SELECT group_id FROM Study_Group WHERE leader_id = ?)");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete all messages in groups this user leads
            ps = conn.prepareStatement("DELETE FROM Message WHERE group_id IN (SELECT group_id FROM Study_Group WHERE leader_id = ?)");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete all memberships in groups this user leads
            ps = conn.prepareStatement("DELETE FROM Membership WHERE group_id IN (SELECT group_id FROM Study_Group WHERE leader_id = ?)");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete the groups themselves
            ps = conn.prepareStatement("DELETE FROM Study_Group WHERE leader_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete this user's replies in other groups
            ps = conn.prepareStatement("DELETE FROM Reply WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete this user's messages in other groups
            ps = conn.prepareStatement("DELETE FROM Message WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete this user's memberships in other groups
            ps = conn.prepareStatement("DELETE FROM Membership WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete student or admin subtype row
            ps = conn.prepareStatement("DELETE FROM Student WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            ps = conn.prepareStatement("DELETE FROM Administrator WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            // Delete user row
            ps = conn.prepareStatement("DELETE FROM User WHERE user_id = ?");
            ps.setInt(1, userId); ps.executeUpdate(); ps.close();

            conn.commit();

            session.invalidate();
            response.sendRedirect("login.jsp?deleted=true");
            return;

        } catch (Exception e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ignored) {}
            error = "Database error: " + e.getMessage();
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ignored) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Delete Account – StudyMatch</title>
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
            <span style="color:var(--sm-text-muted);font-size:0.9rem;padding:0.35rem 0.7rem;">
                <%= userName %>
            </span>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label" style="color:#dc2626;">Danger zone</div>
            <h2 style="margin:0 0 0.4rem;">Delete your account</h2>
            <p>This action is <strong>permanent</strong> and cannot be undone. All of your data will be removed, including:</p>

            <ul style="font-size:0.9rem;color:var(--sm-text-muted);margin:0 0 1.25rem 1.2rem;line-height:1.8;">
                <li>Your profile and account credentials</li>
                <li>Study groups you lead (and their memberships, messages, and schedules)</li>
                <li>Your memberships in other groups</li>
                <li>Messages and replies you have posted</li>
            </ul>

            <% if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form id="deleteForm" method="post" action="deleteAccount.jsp">
                <button type="button" id="deleteBtn"
                        class="sm-btn sm-full-width"
                        style="background:#dc2626;color:#fff;border:none;cursor:pointer;
                               padding:0.65rem 1rem;border-radius:8px;font-size:0.95rem;
                               font-weight:600;">
                    Delete my account
                </button>
            </form>

            <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                Changed your mind? <a href="dashboard.jsp" style="color:var(--sm-primary);">Go back to dashboard</a>
            </p>

        </div>
    </div>
</main>

<footer class="sm-footer">
    <div class="sm-container sm-footer-content">
        <span>© <%= java.time.Year.now() %> StudyMatch</span>
        <span>Built for collaborative learning in higher education.</span>
    </div>
</footer>

<script>
    document.getElementById("deleteBtn").addEventListener("click", function () {
        if (confirm("Are you sure you want to permanently delete your account?\nThis cannot be undone.")) {
            document.getElementById("deleteForm").submit();
        }
    });
</script>

</body>
</html>
