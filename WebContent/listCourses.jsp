<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String DB_URL  = "jdbc:mysql://localhost:3306/StudyMatch";
    String DB_USER = "root";
    String DB_PASS = "CS157A@sjsu";

    String message = null;
    boolean isAdmin = "Admin".equals(session.getAttribute("role"));

    String deletedParam   = request.getParameter("deleted");
    String errorParam     = request.getParameter("error");
    String errorCourseId  = request.getParameter("courseId");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Courses – StudyMatch</title>
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
            <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Back to Dashboard</a>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="margin-top:2.5rem;">

        <div class="sm-small-label">Courses</div>
        <h1 style="margin:0 0 1.5rem;">All Courses</h1>

        <% if (deletedParam != null && !deletedParam.isBlank()) { %>
            <div style="background:#dcfce7;color:#166534;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:1rem;">
                Course <strong><%= deletedParam %></strong> was deleted.
            </div>
        <% } %>
        <% if ("hasGroups".equals(errorParam)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:1rem;">
                Cannot delete <strong><%= errorCourseId %></strong> — one or more study groups still reference this course.
            </div>
        <% } else if ("notFound".equals(errorParam)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:1rem;">
                Course <strong><%= errorCourseId %></strong> was not found.
            </div>
        <% } else if ("db".equals(errorParam)) { %>
            <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:1rem;">
                Database error while deleting the course.
            </div>
        <% } %>

        <%
            Connection conn = null;
            PreparedStatement ps = null;
            ResultSet rs = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                ps   = conn.prepareStatement(
                    "SELECT c.course_id, c.deptName, c.title, c.term, " +
                    "       COUNT(sg.group_id) AS group_count " +
                    "FROM Course c " +
                    "LEFT JOIN Study_Group sg ON c.course_id = sg.course_id " +
                    "GROUP BY c.course_id, c.deptName, c.title, c.term " +
                    "ORDER BY c.title ASC");
                rs   = ps.executeQuery();

                if (!rs.isBeforeFirst()) {
        %>
                    <p style="color:var(--sm-text-muted);">No courses found.<% if (isAdmin) { %> <a href="createCourse.jsp">Add one.</a><% } %></p>
        <%
                } else {
        %>
                    <table style="width:100%;border-collapse:collapse;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,0.07);">
                        <thead style="background:var(--sm-surface,#f9fafb);">
                            <tr>
                                <th style="text-align:left;padding:0.75rem 1rem;font-size:0.8rem;color:var(--sm-text-muted);font-weight:600;border-bottom:1px solid var(--sm-border,#e5e7eb);">Course ID</th>
                                <th style="text-align:left;padding:0.75rem 1rem;font-size:0.8rem;color:var(--sm-text-muted);font-weight:600;border-bottom:1px solid var(--sm-border,#e5e7eb);">Department</th>
                                <th style="text-align:left;padding:0.75rem 1rem;font-size:0.8rem;color:var(--sm-text-muted);font-weight:600;border-bottom:1px solid var(--sm-border,#e5e7eb);">Title</th>
                                <th style="text-align:left;padding:0.75rem 1rem;font-size:0.8rem;color:var(--sm-text-muted);font-weight:600;border-bottom:1px solid var(--sm-border,#e5e7eb);">Term</th>
                                <% if (isAdmin) { %>
                                    <th style="text-align:left;padding:0.75rem 1rem;font-size:0.8rem;color:var(--sm-text-muted);font-weight:600;border-bottom:1px solid var(--sm-border,#e5e7eb);">Actions</th>
                                <% } %>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            while (rs.next()) {
                                String rowCourseId = rs.getString("course_id");
                                int groupCount     = rs.getInt("group_count");
                        %>
                            <tr onmouseover="this.style.background='#f9fafb'" onmouseout="this.style.background='transparent'">
                                <td style="padding:0.75rem 1rem;border-bottom:1px solid var(--sm-border,#e5e7eb);font-weight:600;font-size:0.9rem;"><%= rowCourseId %></td>
                                <td style="padding:0.75rem 1rem;border-bottom:1px solid var(--sm-border,#e5e7eb);font-size:0.9rem;"><%= rs.getString("deptName") %></td>
                                <td style="padding:0.75rem 1rem;border-bottom:1px solid var(--sm-border,#e5e7eb);font-size:0.9rem;"><%= rs.getString("title") %></td>
                                <td style="padding:0.75rem 1rem;border-bottom:1px solid var(--sm-border,#e5e7eb);font-size:0.9rem;color:var(--sm-text-muted);"><%= rs.getString("term") %></td>
                                <% if (isAdmin) { %>
                                    <td style="padding:0.75rem 1rem;border-bottom:1px solid var(--sm-border,#e5e7eb);font-size:0.9rem;">
                                        <% if (groupCount == 0) { %>
                                            <a href="deleteCourse.jsp?courseId=<%= java.net.URLEncoder.encode(rowCourseId, "UTF-8") %>"
                                               onclick="return confirm('Delete course <%= rowCourseId %>? This cannot be undone.');"
                                               style="color:#dc2626;font-weight:500;text-decoration:none;">
                                                Delete
                                            </a>
                                        <% } else { %>
                                            <span style="display:inline-block;padding:0.2rem 0.55rem;border-radius:99px;background:#f3f4f6;color:var(--sm-text-muted);font-size:0.78rem;">
                                                Has <%= groupCount %> group<%= groupCount == 1 ? "" : "s" %>
                                            </span>
                                        <% } %>
                                    </td>
                                <% } %>
                            </tr>
                        <%
                            }
                        %>
                        </tbody>
                    </table>
        <%
                }
            } catch (Exception e) {
                message = "Database error: " + e.getMessage();
            } finally {
                if (rs   != null) try { rs.close();   } catch (SQLException ignored) {}
                if (ps   != null) try { ps.close();   } catch (SQLException ignored) {}
                if (conn != null) try { conn.close();  } catch (SQLException ignored) {}
            }
        %>

        <% if (message != null) { %>
            <p style="color:#dc2626;margin-top:1rem;"><%= message %></p>
        <% } %>

        <% if (isAdmin) { %>
            <div style="margin-top:1.5rem;">
                <a href="createCourse.jsp" class="sm-btn sm-btn-primary">Add a course</a>
            </div>
        <% } %>

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
