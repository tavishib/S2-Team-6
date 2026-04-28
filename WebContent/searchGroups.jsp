<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    // Session check
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Map<String, String>> results = new ArrayList<>();

    // Get filters
    String courseId  = request.getParameter("courseId");
    String modality  = request.getParameter("modality");
    String location  = request.getParameter("location");
    String status    = request.getParameter("status");
    String meetingDay= request.getParameter("meetingDay");
    String tag       = request.getParameter("tag");

    try (Connection conn = DBConnection.getConnection()) {

        StringBuilder sql = new StringBuilder(
            "SELECT sg.group_id, sg.group_name, sg.course_id, sg.modality, sg.location, sg.max_capacity, sg.current_status, " +
            "COUNT(m.user_id) AS current_members " +
            "FROM Study_Group sg " +
            "LEFT JOIN Membership m ON sg.group_id = m.group_id "
        );

        // Optional joins
        if (meetingDay != null && !meetingDay.isEmpty()) {
            sql.append("JOIN Meeting_Schedule ms ON sg.group_id = ms.group_id ");
        }

        if (tag != null && !tag.isEmpty()) {
            sql.append("JOIN Group_Tag gt ON sg.group_id = gt.group_id ");
            sql.append("JOIN Tag t ON gt.tag_id = t.tag_id ");
        }

        sql.append("WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (courseId != null && !courseId.isEmpty()) {
            sql.append("AND sg.course_id = ? ");
            params.add(courseId);
        }

        if (modality != null && !modality.isEmpty()) {
            sql.append("AND sg.modality = ? ");
            params.add(modality);
        }

        if (location != null && !location.isEmpty()) {
            sql.append("AND sg.location LIKE ? ");
            params.add("%" + location + "%");
        }

        if (status != null && !status.isEmpty()) {
            sql.append("AND sg.current_status = ? ");
            params.add(status);
        }

        if (meetingDay != null && !meetingDay.isEmpty()) {
            sql.append("AND ms.meeting_day = ? ");
            params.add(meetingDay);
        }

        if (tag != null && !tag.isEmpty()) {
            sql.append("AND t.tag_name = ? ");
            params.add(tag);
        }

        sql.append("GROUP BY sg.group_id ");
        sql.append("ORDER BY sg.group_id DESC");

        PreparedStatement ps = conn.prepareStatement(sql.toString());

        for (int i = 0; i < params.size(); i++) {
            ps.setObject(i + 1, params.get(i));
        }

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String, String> row = new HashMap<>();

            int maxCap = rs.getInt("max_capacity");
            int curr   = rs.getInt("current_members");

            row.put("name", rs.getString("group_name"));
            row.put("course", rs.getString("course_id"));
            row.put("modality", rs.getString("modality"));
            row.put("location", rs.getString("location"));
            row.put("status", rs.getString("current_status"));
            row.put("capacity", (maxCap - curr) + " spots left");

            results.add(row);
        }

    } catch (SQLException e) {
        request.setAttribute("error", e.getMessage());
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Search Groups – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>

<h2>Search Study Groups</h2>

<!-- SEARCH FORM -->
<form method="get">

    <input type="text" name="courseId" placeholder="Course ID">

    <select name="modality">
        <option value="">Any Modality</option>
        <option value="Online">Online</option>
        <option value="In-Person">In-Person</option>
        <option value="Hybrid">Hybrid</option>
    </select>

    <input type="text" name="location" placeholder="Location">

    <select name="status">
        <option value="">Any Status</option>
        <option value="Public">Public</option>
        <option value="Private">Private</option>
    </select>

    <select name="meetingDay">
        <option value="">Any Day</option>
        <option value="Monday">Monday</option>
        <option value="Tuesday">Tuesday</option>
        <option value="Wednesday">Wednesday</option>
    </select>

    <select name="tag">
        <option value="">Any Tag</option>
        <option value="Homework">Homework</option>
        <option value="Exam Prep">Exam Prep</option>
        <option value="Project">Project</option>
    </select>

    <button type="submit">Search</button>
</form>

<hr>

<!-- ERROR -->
<%
String error = (String) request.getAttribute("error");
if (error != null) {
%>
    <p style="color:red;"><%= error %></p>
<%
}
%>

<!-- RESULTS -->
<h3>Results</h3>

<%
if (results.isEmpty()) {
%>
    <p>No groups found.</p>
<%
} else {
    for (Map<String, String> g : results) {
%>
    <div style="border:1px solid #ccc; padding:10px; margin:10px 0;">
        <h4><%= g.get("name") %></h4>
        <p><b>Course:</b> <%= g.get("course") %></p>
        <p><b>Modality:</b> <%= g.get("modality") %></p>
        <p><b>Location:</b> <%= g.get("location") %></p>
        <p><b>Status:</b> <%= g.get("status") %></p>
        <p><b>Capacity:</b> <%= g.get("capacity") %></p>
    </div>
<%
    }
}
%>

</body>
</html>