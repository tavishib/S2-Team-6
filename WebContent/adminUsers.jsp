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

    //check if user is admin, if not redirect to dashboard
    if (!"Admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");
    int currentAdminId = (Integer) session.getAttribute("userId");

    String resetUserId   = request.getParameter("reset");
    String resetTemp     = request.getParameter("temp");
    String resetUserName = request.getParameter("userName");
    String adminError    = request.getParameter("error");
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
            <a href="adminGroups.jsp" class="sm-btn sm-btn-outline">Manage Groups</a>
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
            Ban or unban users, or issue a one-time password reset.
        </p>

        <% if (resetUserId != null && resetTemp != null) { %>
            <div style="background:#fef9c3;color:#854d0e;border:1px solid #fde68a;border-radius:10px;padding:0.85rem 1rem;margin:1rem 0;font-size:0.9rem;line-height:1.6;">
                <div style="font-weight:600;margin-bottom:0.3rem;">
                    Temporary password issued
                    <% if (resetUserName != null && !resetUserName.isBlank()) { %>
                        for <%= resetUserName %> (#<%= resetUserId %>)
                    <% } else { %>
                        for user #<%= resetUserId %>
                    <% } %>
                </div>
                <div>
                    <span style="display:inline-block;background:#fff;border:1px solid #fde68a;border-radius:6px;padding:0.25rem 0.6rem;font-family:monospace;font-size:0.95rem;user-select:all;">
                        <%= resetTemp %>
                    </span>
                </div>
                <div style="margin-top:0.5rem;font-size:0.82rem;color:#854d0e;">
                    Share this with the user through a secure channel. It will <strong>not be shown again</strong>. They will be required to set a new password on next login.
                </div>
            </div>
        <% } %>

        <% if ("selfReset".equals(adminError)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                You cannot reset your own password from here. Use Change password in the dashboard settings menu.
            </div>
        <% } else if ("adminProtected".equals(adminError)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                Another admin's password cannot be reset from this panel.
            </div>
        <% } else if ("deletedUser".equals(adminError)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                That account has been deleted.
            </div>
        <% } else if ("notFound".equals(adminError)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                User not found.
            </div>
        <% } else if ("db".equals(adminError)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                Database error while processing the request.
            </div>
        <% } %>

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
                                "LEFT JOIN Administrator a ON u.user_id = a.user_id " + //allows admins to see every user in the system while identifying who else has admin priviledges
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
                            <% } else { %>
                                <div style="display:flex;gap:0.4rem;flex-wrap:wrap;">
                                    <% if (isBanned) { %>
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
                                    <a href="adminResetPassword.jsp?userId=<%= userId %>"
                                       class="sm-btn sm-btn-outline"
                                       style="font-size:0.8rem;padding:0.25rem 0.65rem;"
                                       onclick="return confirm('Issue a one-time temporary password for this user? Their current password will stop working.');">
                                        Reset password
                                    </a>
                                </div>
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