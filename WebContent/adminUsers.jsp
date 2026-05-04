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

    if (!"Admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");
    int currentAdminId = (Integer) session.getAttribute("userId");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Users – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="dashboard.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
            <span>admin panel</span>
        </a>
        <nav class="sm-nav">
            <span style="color:var(--sm-text-muted);font-size:0.9rem;padding:0.35rem 0.7rem;">
                <%= userName %>
            </span>
            <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Dashboard</a>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="margin-top:2rem;">
        <div class="sm-small-label">Admin Panel</div>
        <h1>Manage Users</h1>
        <p style="color:var(--sm-text-muted);">
            Ban or unban users from accessing StudyMatch.
        </p>

        <div class="sm-dashboard-side sm-quick-card" style="margin-top:1rem;">
            <table style="width:100%;border-collapse:collapse;font-size:0.9rem;">
                <thead>
                    <tr style="text-align:left;border-bottom:1px solid var(--sm-border);">
                        <th style="padding:0.75rem;">ID</th>
                        <th style="padding:0.75rem;">Name</th>
                        <th style="padding:0.75rem;">Email</th>
                        <th style="padding:0.75rem;">Role</th>
                        <th style="padding:0.75rem;">Status</th>
                        <th style="padding:0.75rem;">Action</th>
                    </tr>
                </thead>
                <tbody>

                <%
                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");

                        try (Connection conn = DriverManager.getConnection(
                                "jdbc:mysql://localhost:3306/StudyMatch",
                                "root",
                                "CS157A@sjsu")) {

                            PreparedStatement ps = conn.prepareStatement(
                                "SELECT u.user_id, u.name, u.email, u.is_banned, " +
                                "CASE WHEN a.user_id IS NOT NULL THEN 'Admin' ELSE 'Student' END AS role " +
                                "FROM User u " +
                                "LEFT JOIN Administrator a ON u.user_id = a.user_id " +
                                "ORDER BY role, u.user_id"
                            );

                            ResultSet rs = ps.executeQuery();

                            while (rs.next()) {
                                int userId = rs.getInt("user_id");
                                boolean isBanned = rs.getBoolean("is_banned");
                                String role = rs.getString("role");
                %>

                    <tr style="border-bottom:1px solid var(--sm-border);">
                        <td style="padding:0.75rem;"><%= userId %></td>
                        <td style="padding:0.75rem;"><%= rs.getString("name") %></td>
                        <td style="padding:0.75rem;"><%= rs.getString("email") %></td>
                        <td style="padding:0.75rem;"><%= role %></td>
                        <td style="padding:0.75rem;">
                            <% if (isBanned) { %>
                                <span style="color:#dc2626;font-weight:600;">Banned</span>
                            <% } else { %>
                                <span style="color:#16a34a;font-weight:600;">Active</span>
                            <% } %>
                        </td>
                        <td style="padding:0.75rem;">
                            <% if (userId == currentAdminId) { %>
                                <span style="color:var(--sm-text-muted);font-size:0.85rem;">Current admin</span>
                            <% } else if ("Admin".equals(role)) { %>
                                <span style="color:var(--sm-text-muted);font-size:0.85rem;">Admin protected</span>
                            <% } else if (isBanned) { %>
                                <a href="unbanUser.jsp?userId=<%= userId %>"
                                   class="sm-btn sm-btn-outline"
                                   style="font-size:0.8rem;padding:0.25rem 0.65rem;"
                                   onclick="return confirm('Unban this user?');">
                                    Unban
                                </a>
                            <% } else { %>
                                <a href="banUser.jsp?userId=<%= userId %>"
                                   class="sm-btn sm-btn-outline"
                                   style="font-size:0.8rem;padding:0.25rem 0.65rem;color:#dc2626;border-color:#dc2626;"
                                   onclick="return confirm('Ban this user?');">
                                    Ban
                                </a>
                            <% } %>
                        </td>
                    </tr>

                <%
                            }

                            rs.close();
                            ps.close();
                        }
                    } catch (Exception e) {
                %>
                    <tr>
                        <td colspan="6" style="padding:1rem;color:#dc2626;">
                            Error loading users: <%= e.getMessage() %>
                        </td>
                    </tr>
                <%
                    }
                %>

                </tbody>
            </table>
        </div>
    </div>
</main>

<footer class="sm-footer">
    <div class="sm-container sm-footer-content">
        <span>© <%= java.time.Year.now() %> StudyMatch</span>
        <span>Admin user management.</span>
    </div>
</footer>

</body>
</html>