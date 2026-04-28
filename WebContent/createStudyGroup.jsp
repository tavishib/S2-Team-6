<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    // Prevent caching
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Session check
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");

    if ("POST".equalsIgnoreCase(request.getMethod())) {

        int userId = (int) session.getAttribute("userId");

        String courseId    = request.getParameter("courseId");
        String groupName   = request.getParameter("groupName");
        String description = request.getParameter("description");
        String modality    = request.getParameter("modality");
        String status      = request.getParameter("status");
        String location    = request.getParameter("location");
        int maxCapacity    = Integer.parseInt(request.getParameter("maxCapacity"));

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(
                    "jdbc:mysql://localhost:3306/StudyMatch",
                    "root",
                    "CS157A@sjsu")) {

                conn.setAutoCommit(false);

                try {
                    // Insert group
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Study_Group (course_id, leader_id, group_name, description, modality, max_capacity, current_status, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS
                    );

                    ps.setString(1, courseId);
                    ps.setInt(2, userId);
                    ps.setString(3, groupName);
                    ps.setString(4, description);
                    ps.setString(5, modality);
                    ps.setInt(6, maxCapacity);
                    ps.setString(7, status);
                    ps.setString(8, location);

                    ps.executeUpdate();

                    // Get group_id
                    ResultSet rs = ps.getGeneratedKeys();
                    int groupId = 0;
                    if (rs.next()) {
                        groupId = rs.getInt(1);
                    }

                    // Add creator as leader/member
                    ps = conn.prepareStatement(
                        "INSERT INTO Membership (user_id, group_id, joined_at, membership_role, membership_status) VALUES (?, ?, NOW(), 'Leader', 'Active')"
                    );

                    ps.setInt(1, userId);
                    ps.setInt(2, groupId);
                    ps.executeUpdate();

                    conn.commit();

                    response.sendRedirect("dashboard.jsp");
                    return;

                } catch (SQLException e) {
                    conn.rollback();
                    request.setAttribute("error", "Database error: " + e.getMessage());
                }
            }

        } catch (Exception e) {
            request.setAttribute("error", "Database error: " + e.getMessage());
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Create Study Group – StudyMatch</title>
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
            <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Back</a>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:600px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label">Study Groups</div>
            <h2>Create a study group</h2>
            <p>Fill in the details to create a new study group.</p>

            <% String error = (String) request.getAttribute("error");
               if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

                <div class="sm-field-group">
                    <label>Course ID</label>
                    <input class="sm-input" type="text" name="courseId" required>
                </div>

                <div class="sm-field-group">
                    <label>Group Name</label>
                    <input class="sm-input" type="text" name="groupName" required>
                </div>

                <div class="sm-field-group">
                    <label>Description</label>
                    <textarea class="sm-input" name="description"></textarea>
                </div>

                <div class="sm-field-group">
                    <label>Modality</label>
                    <select class="sm-select" name="modality">
                        <option value="Online">Online</option>
                        <option value="In-Person">In-Person</option>
                        <option value="Hybrid">Hybrid</option>
                    </select>
                </div>

                <div class="sm-field-group">
                    <label>Status</label>
                    <select class="sm-select" name="status">
                        <option value="Public">Public</option>
                        <option value="Private">Private</option>
                    </select>
                </div>

                <div class="sm-field-group">
                    <label>Location</label>
                    <input class="sm-input" type="text" name="location">
                </div>

                <div class="sm-field-group">
                    <label>Max Capacity</label>
                    <input class="sm-input" type="number" name="maxCapacity" required>
                </div>

                <button type="submit" class="sm-btn sm-btn-primary sm-full-width">
                    Create Group
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