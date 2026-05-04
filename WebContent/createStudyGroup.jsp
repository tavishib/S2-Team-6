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
        String passcode    = request.getParameter("passcode");
        String tagsRaw     = request.getParameter("tags");
        int maxCapacity    = Integer.parseInt(request.getParameter("maxCapacity"));
        String meetingDay    = request.getParameter("meetingDay");
        String startTime     = request.getParameter("startTime");
        String endTime       = request.getParameter("endTime");
        String meetingType   = request.getParameter("meetingType");

        if ("Private".equals(status) && (passcode == null || passcode.isBlank())) {
            request.setAttribute("error", "A passcode is required for private groups.");
        } else {

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
                        "INSERT INTO Study_Group (course_id, leader_id, group_name, description, modality, max_capacity, current_status, passcode, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        Statement.RETURN_GENERATED_KEYS
                    );

                    ps.setString(1, courseId);
                    ps.setInt(2, userId);
                    ps.setString(3, groupName);
                    ps.setString(4, description);
                    ps.setString(5, modality);
                    ps.setInt(6, maxCapacity);
                    ps.setString(7, status);
                    ps.setString(8, "Private".equals(status) ? passcode.trim() : null);
                    ps.setString(9, location);

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

                    // Insert tags into Tag (if new) and link via Group_Tag
                    if (tagsRaw != null && !tagsRaw.isBlank()) {
                        for (String rawTag : tagsRaw.split(",")) {
                            String tagName = rawTag.trim();
                            if (tagName.isEmpty()) continue;

                            // Create tag if it doesn't exist
                            PreparedStatement tagPs = conn.prepareStatement(
                                "INSERT IGNORE INTO Tag (tag_name) VALUES (?)");
                            tagPs.setString(1, tagName);
                            tagPs.executeUpdate();
                            tagPs.close();

                            // Get tag_id
                            PreparedStatement tagId = conn.prepareStatement(
                                "SELECT tag_id FROM Tag WHERE tag_name = ?");
                            tagId.setString(1, tagName);
                            ResultSet tagRs = tagId.executeQuery();
                            if (tagRs.next()) {
                                PreparedStatement gtPs = conn.prepareStatement(
                                    "INSERT IGNORE INTO Group_Tag (group_id, tag_id) VALUES (?, ?)");
                                gtPs.setInt(1, groupId);
                                gtPs.setInt(2, tagRs.getInt("tag_id"));
                                gtPs.executeUpdate();
                                gtPs.close();
                            }
                            tagId.close();
                        }
                    }

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
        } // end else (passcode validation passed)
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
                    <label>Visibility</label>
                    <select class="sm-select" name="status" id="statusSelect"
                            onchange="document.getElementById('passcodeField').style.display=
                                      this.value==='Private'?'flex':'none'">
                        <option value="Public">Public — anyone can join</option>
                        <option value="Private">Private — passcode required</option>
                    </select>
                </div>

                <div class="sm-field-group" id="passcodeField" style="display:none;">
                    <label for="passcode">Passcode</label>
                    <input id="passcode" class="sm-input" type="text" name="passcode"
                           placeholder="Set a passcode for members to use">
                </div>

                <div class="sm-field-group">
                    <label>Location</label>
                    <input class="sm-input" type="text" name="location">
                </div>

                <div class="sm-field-group">
                    <label>Max Capacity</label>
                    <input class="sm-input" type="number" name="maxCapacity" required>
                </div>

                <div class="sm-field-group">
                    <label>Tags <span style="font-weight:400;color:var(--sm-text-muted);">(optional, comma-separated)</span></label>
                    <input class="sm-input" type="text" name="tags"
                           placeholder="e.g. Exam Prep, Algorithms, Project">
                    <span style="font-size:0.78rem;color:var(--sm-text-muted);margin-top:0.2rem;">
                        New tags are created automatically.
                    </span>
                </div>

                <div class="sm-field-group">
                    <label>Meeting Day</label>
                    <select name="meetingDay" class="sm-select">
                        <option>Monday</option>
                        <option>Tuesday</option>
                        <option>Wednesday</option>
                        <option>Thursday</option>
                        <option>Friday</option>
                        <option>Saturday</option>
                        <option>Sunday</option>
                    </select>
                </div>

                <div class="sm-field-group">
                    <label>Start Time</label>
                    <input type="time" name="startTime" class="sm-input">
                </div>

                <div class="sm-field-group">
                    <label>End Time</label>
                    <input type="time" name="endTime" class="sm-input">
                </div>

                <div class="sm-field-group">
                    <label>Meeting Type</label>
                    <select name="meetingType" class="sm-select">
                        <option value="Online">Online</option>
                        <option value="In-Person">In-Person</option>
                    </select>
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