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
    java.util.List<int[]> ledGroups = new java.util.ArrayList<>(); // [group_id]
    java.util.List<String> ledGroupNames = new java.util.ArrayList<>();

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

            // Pre-check: block deletion if the user leads any study group.
            PreparedStatement leadCheck = conn.prepareStatement(
                "SELECT group_id, group_name FROM Study_Group WHERE leader_id = ?");
            leadCheck.setInt(1, userId);
            ResultSet leadRs = leadCheck.executeQuery();
            while (leadRs.next()) {
                ledGroups.add(new int[]{ leadRs.getInt("group_id") });
                ledGroupNames.add(leadRs.getString("group_name"));
            }
            leadRs.close();
            leadCheck.close();

            if (!ledGroups.isEmpty()) {
                error = "You still lead study group(s). Delete or transfer leadership before deleting your account.";
            } else {
                conn.setAutoCommit(false);
                try {
                    // Preserve discussion: detach this user from their messages and replies.
                    PreparedStatement ps;

                    ps = conn.prepareStatement("UPDATE Reply SET user_id = NULL WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    ps = conn.prepareStatement("UPDATE Message SET user_id = NULL WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    ps = conn.prepareStatement("DELETE FROM Membership WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    ps = conn.prepareStatement("DELETE FROM Student WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    ps = conn.prepareStatement("DELETE FROM Administrator WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    ps = conn.prepareStatement("DELETE FROM User WHERE user_id = ?");
                    ps.setInt(1, userId); ps.executeUpdate(); ps.close();

                    conn.commit();
                } catch (SQLException txEx) {
                    conn.rollback();
                    throw txEx;
                }

                session.invalidate();
                response.sendRedirect("login.jsp?deleted=true");
                return;
            }
        } catch (Exception e) {
            error = "Database error: " + e.getMessage();
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
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
            <p>This action is <strong>permanent</strong> and cannot be undone. When you delete your account:</p>

            <ul style="font-size:0.9rem;color:var(--sm-text-muted);margin:0 0 1.25rem 1.2rem;line-height:1.8;">
                <li>Your profile and account credentials are removed</li>
                <li>Your memberships in study groups are removed</li>
                <li>Your name is removed from messages and replies you have posted (the posts themselves stay, shown as "Deleted user")</li>
            </ul>

            <p style="font-size:0.85rem;color:var(--sm-text-muted);margin:0 0 1rem;">
                If you lead any study groups, you must delete or transfer leadership of them first.
            </p>

            <% if (!ledGroups.isEmpty()) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.7rem 0.9rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <strong>You still lead the following group(s):</strong>
                    <ul style="margin:0.4rem 0 0 1.1rem;padding:0;">
                        <% for (int i = 0; i < ledGroups.size(); i++) {
                               int gid = ledGroups.get(i)[0];
                               String gname = ledGroupNames.get(i); %>
                            <li>
                                <a href="groupDetail.jsp?groupId=<%= gid %>" style="color:#991b1b;text-decoration:underline;">
                                    <%= gname %>
                                </a>
                            </li>
                        <% } %>
                    </ul>
                </div>
            <% } else if (error != null) { %>
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
