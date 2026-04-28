<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Map<String, String>> results = new ArrayList<>();

    String courseId   = request.getParameter("courseId");
    String modality   = request.getParameter("modality");
    String location   = request.getParameter("location");
    String status     = request.getParameter("status");
    String meetingDay = request.getParameter("meetingDay");
    String tag        = request.getParameter("tag");
    int uId           = (int) session.getAttribute("userId");

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        StringBuilder sql = new StringBuilder(
            "SELECT sg.group_id, sg.group_name, sg.course_id, sg.modality, sg.location, sg.max_capacity, sg.current_status, " +
            "COUNT(m.user_id) AS current_members " +
            "FROM Study_Group sg " +
            "LEFT JOIN Membership m ON sg.group_id = m.group_id "
        );

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

        sql.append("GROUP BY sg.group_id ORDER BY sg.group_id DESC");

        PreparedStatement ps = conn.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) {
            ps.setObject(i + 1, params.get(i));
        }

        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String, String> row = new HashMap<>();
            int maxCap = rs.getInt("max_capacity");
            int curr   = rs.getInt("current_members");
            int gId    = rs.getInt("group_id");

            row.put("groupId",  String.valueOf(gId));
            row.put("name",     rs.getString("group_name"));
            row.put("course",   rs.getString("course_id"));
            row.put("modality", rs.getString("modality"));
            row.put("location", rs.getString("location"));
            row.put("status",   rs.getString("current_status"));
            row.put("capacity", (maxCap - curr) + " spots left");

            PreparedStatement memberCheck = conn.prepareStatement(
                "SELECT 1 FROM Membership WHERE user_id = ? AND group_id = ?");
            memberCheck.setInt(1, uId);
            memberCheck.setInt(2, gId);
            ResultSet mRs = memberCheck.executeQuery();
            row.put("memberStatus", mRs.next() ? "Member" : "NotMember");

            results.add(row);
        }

        conn.close();

    } catch (Exception e) {
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

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="dashboard.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
        </a>
        <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Back</a>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:600px; margin-top:2rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <h2>Search Study Groups</h2>

            <form method="get" style="display:flex;flex-direction:column;gap:0.7rem;">

                <input class="sm-input" type="text" name="courseId" placeholder="Course ID">

                <select class="sm-select" name="modality">
                    <option value="">Any Modality</option>
                    <option value="Online">Online</option>
                    <option value="In-Person">In-Person</option>
                    <option value="Hybrid">Hybrid</option>
                </select>

                <input class="sm-input" type="text" name="location" placeholder="Location">

                <select class="sm-select" name="status">
                    <option value="">Any Status</option>
                    <option value="Public">Public</option>
                    <option value="Private">Private</option>
                </select>

                <select class="sm-select" name="meetingDay">
                    <option value="">Any Day</option>
                    <option value="Monday">Monday</option>
                    <option value="Tuesday">Tuesday</option>
                    <option value="Wednesday">Wednesday</option>
                </select>

                <select class="sm-select" name="tag">
                    <option value="">Any Tag</option>
                    <option value="Homework">Homework</option>
                    <option value="Exam Prep">Exam Prep</option>
                    <option value="Project">Project</option>
                </select>

                <button class="sm-btn sm-btn-primary">Search</button>
            </form>
        </div>
    </div>

    <div class="sm-container" style="max-width:600px; margin-top:1rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <h3>Results</h3>

            <% String error = (String) request.getAttribute("error");
               if (error != null) { %>
                <p style="color:red;"><%= error %></p>
            <% } %>

            <% if (results.isEmpty()) { %>
                <p>No groups found.</p>
            <% } else {
                for (Map<String, String> g : results) { %>

                <div style="border:1px solid #eee;padding:10px;border-radius:8px;margin:10px 0;">
				    <h4><%= g.get("name") %></h4>
				    <p>Course: <%= g.get("course") %></p>
				    <p>Modality: <%= g.get("modality") %></p>
				    <p>Location: <%= g.get("location") %></p>
				    <p>Status: <%= g.get("status") %></p>
				    <p>Capacity: <%= g.get("capacity") %></p>
				    <% if (!"0 spots left".equals(g.get("capacity")) && !"Member".equals(g.get("memberStatus"))) { %>
				        <a href="joinGroup.jsp?groupId=<%= g.get("groupId") %>" class="sm-btn sm-btn-primary">Join</a>
				    <% } else if ("Member".equals(g.get("memberStatus"))) { %>
				        <span style="color:green;">✓ Joined</span>
				    <% } else { %>
				        <span style="color:gray;">Full</span>
				    <% } %>
				</div>

            <% } } %>

        </div>
    </div>
</main>

</body>
</html>