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

    String error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String courseId = request.getParameter("course_id");
        String deptName = request.getParameter("deptName");
        String title    = request.getParameter("title");
        String term     = request.getParameter("term");

        if (courseId == null || courseId.isBlank() || deptName == null || deptName.isBlank() ||
            title == null || title.isBlank() || term == null || term.isBlank()) {
            error = "All fields are required.";
        } else {
            Connection conn = null;
            PreparedStatement ps = null;
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch", "root", "mysql@1234");

                ps = conn.prepareStatement("INSERT INTO Course (course_id, deptName, title, term) VALUES (?, ?, ?, ?)");
                ps.setString(1, courseId.trim());
                ps.setString(2, deptName.trim());
                ps.setString(3, title.trim());
                ps.setString(4, term.trim());
                ps.executeUpdate();

                response.sendRedirect("dashboard.jsp");
                return;
            } catch (Exception e) {
                error = "Database error: " + e.getMessage();
            } finally {
                if (ps   != null) try { ps.close();   } catch (SQLException ignored) {}
                if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Create Course – StudyMatch</title>
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
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:600px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">
            <div class="sm-small-label">Courses</div>
            <h2 style="margin:0 0 0.4rem;">Create a course</h2>
            <p>Add a course to the StudyMatch system.</p>

            <% if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form action="createCourse.jsp" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

                <div class="sm-field-group">
                    <label for="course_id">Course ID</label>
                    <input id="course_id" class="sm-input" type="text" name="course_id" placeholder="e.g. CS157A" required>
                </div>

                <div class="sm-field-group">
                    <label for="deptName">Department Name</label>
                    <input id="deptName" class="sm-input" type="text" name="deptName" placeholder="e.g. Computer Science" required>
                </div>

                <div class="sm-field-group">
                    <label for="title">Course Title</label>
                    <input id="title" class="sm-input" type="text" name="title" placeholder="e.g. Database Management Systems" required>
                </div>

                <div class="sm-field-group">
                    <label for="term">Term</label>
                    <input id="term" class="sm-input" type="text" name="term" placeholder="e.g. Spring 2026" required>
                </div>

                <button type="submit" class="sm-btn sm-btn-primary sm-full-width">
                    Create Course
                </button>
            </form>
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
