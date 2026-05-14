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

    String userName       = (String) session.getAttribute("userName");
    String deletedParam   = request.getParameter("deleted");
    String errorParam     = request.getParameter("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Groups – StudyMatch</title>
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
            <a href="adminUsers.jsp" class="sm-btn sm-btn-outline">Manage Users</a>
            <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Dashboard</a>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="margin-top:2rem;">
        <div class="sm-small-label">Admin Panel</div>
        <h1>Manage Study Groups</h1>
        <p style="color:var(--sm-text-muted);">
            Review all study groups on the platform and remove any that violate policy.
        </p>

        <% if (deletedParam != null && !deletedParam.isBlank()) { %>
            <div style="background:#dcfce7;color:#166534;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                Group <strong>#<%= deletedParam %></strong> was deleted.
            </div>
        <% } %>
        <% if ("db".equals(errorParam)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin:1rem 0;">
                Database error while deleting the group.
            </div>
        <% } %>

        <div class="sm-dashboard-side sm-quick-card" style="margin-top:1rem;">
            <table style="width:100%;border-collapse:collapse;font-size:0.9rem;">
                <thead>
                    <tr style="text-align:left;border-bottom:1px solid var(--sm-border);">
                        <th style="padding:0.75rem;">ID</th>
                        <th style="padding:0.75rem;">Group Name</th>
                        <th style="padding:0.75rem;">Course</th>
                        <th style="padding:0.75rem;">Leader</th>
                        <th style="padding:0.75rem;">Members</th>
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
                                "SELECT sg.group_id, sg.group_name, sg.course_id, sg.current_status, " +
                                "       u.name AS leader_name, " +
                                "       (SELECT COUNT(*) FROM Membership m " +
                                "         WHERE m.group_id = sg.group_id AND m.membership_status = 'Active') AS member_count " +
                                "FROM Study_Group sg " +
                                "LEFT JOIN User u ON sg.leader_id = u.user_id " +
                                "ORDER BY sg.group_id ASC"
                            );

                            ResultSet rs = ps.executeQuery();
                            boolean any = false;

                            while (rs.next()) {
                                any = true;
                                int groupId       = rs.getInt("group_id");
                                String groupName  = rs.getString("group_name");
                                String courseId   = rs.getString("course_id");
                                String leaderName = rs.getString("leader_name");
                                int memberCount   = rs.getInt("member_count");
                                String status     = rs.getString("current_status");
                %>

                    <tr style="border-bottom:1px solid var(--sm-border);">
                        <td style="padding:0.75rem;"><%= groupId %></td>
                        <td style="padding:0.75rem;font-weight:500;">
                            <a href="groupDetail.jsp?groupId=<%= groupId %>"
                               style="color:var(--sm-text);text-decoration:none;"
                               onmouseover="this.style.color='var(--sm-primary)'"
                               onmouseout="this.style.color='var(--sm-text)'">
                                <%= groupName != null ? groupName : "(unnamed)" %>
                            </a>
                        </td>
                        <td style="padding:0.75rem;"><%= courseId != null ? courseId : "—" %></td>
                        <td style="padding:0.75rem;"><%= leaderName != null ? leaderName : "—" %></td>
                        <td style="padding:0.75rem;"><%= memberCount %></td>
                        <td style="padding:0.75rem;">
                            <% if ("Active".equals(status)) { %>
                                <span style="color:#16a34a;font-weight:600;"><%= status %></span>
                            <% } else { %>
                                <span style="color:var(--sm-text-muted);font-weight:500;"><%= status != null ? status : "—" %></span>
                            <% } %>
                        </td>
                        <td style="padding:0.75rem;">
                            <a href="deleteGroup.jsp?groupId=<%= groupId %>&from=admin"
                               class="sm-btn sm-btn-outline"
                               style="font-size:0.8rem;padding:0.25rem 0.65rem;color:#dc2626;border-color:#dc2626;"
                               onclick="return confirm('Delete group #<%= groupId %> (<%= groupName != null ? groupName.replace("'", "\\'") : "" %>)? This cannot be undone.');">
                                Delete
                            </a>
                        </td>
                    </tr>

                <%
                            }

                            if (!any) {
                %>
                    <tr>
                        <td colspan="7" style="padding:1rem;color:var(--sm-text-muted);">
                            No study groups on the platform yet.
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
                        <td colspan="7" style="padding:1rem;color:#dc2626;">
                            Error loading groups: <%= e.getMessage() %>
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
        <span>Admin group management.</span>
    </div>
</footer>

</body>
</html>
