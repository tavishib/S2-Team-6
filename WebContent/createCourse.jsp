<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
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

            <form action="createCourse" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

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