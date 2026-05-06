<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Map<String, String>> results = new ArrayList<>();
    boolean searched = "1".equals(request.getParameter("searched"));

    String groupIdSearch = request.getParameter("groupId");
    String courseId      = request.getParameter("courseId");
    String modality      = request.getParameter("modality");
    String location      = request.getParameter("location");
    String status        = request.getParameter("status");
    String meetingDay    = request.getParameter("meetingDay");
    String tag           = request.getParameter("tag");
    int uId              = (int) session.getAttribute("userId");

    if (searched) try {
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
        
        // Base condition to simplify appending AND clauses
        sql.append("WHERE 1=1 ");

        List<Object> params = new ArrayList<>();

        if (groupIdSearch != null && !groupIdSearch.isEmpty()) {
            try {
                sql.append("AND sg.group_id = ? ");
                params.add(Integer.parseInt(groupIdSearch.trim()));
            } catch (NumberFormatException ignored) {}
        }
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

        //checks if the user is already a member of the group, to prevent showing join button for those groups
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
    } // end if (searched)
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
                <input type="hidden" name="searched" value="1">

                <input class="sm-input" type="number" name="groupId" placeholder="Group ID (e.g. 3)"
                       min="1" value="<%= groupIdSearch != null ? groupIdSearch : "" %>">

                <input class="sm-input" type="text" name="courseId" placeholder="Course ID"
                       value="<%= courseId != null ? courseId : "" %>">

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


                <!-- <select class="sm-select" name="meetingDay">
                    <option value="">Any Day</option>
                    <option value="Monday">Monday</option>
                    <option value="Tuesday">Tuesday</option>
                    <option value="Wednesday">Wednesday</option>
                </select> -->

                <!-- <select class="sm-select" name="tag">
                    <option value="">Any Tag</option>
                    <option value="Homework">Homework</option>
                    <option value="Exam Prep">Exam Prep</option>
                    <option value="Project">Project</option>
                </select> -->

                <button class="sm-btn sm-btn-primary">Search</button>
            </form>
        </div>
    </div>

    <% if (searched) { %>
    <div class="sm-container" style="max-width:600px; margin-top:1rem;">
        <div class="sm-dashboard-side sm-quick-card" style="padding:1rem 1.2rem;">

            <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:0.75rem;">
                <h3 style="margin:0;font-size:1rem;">Results</h3>
                <% if (!results.isEmpty()) { %>
                    <span style="font-size:0.78rem;color:var(--sm-text-muted);"><%= results.size() %> group<%= results.size() == 1 ? "" : "s" %></span>
                <% } %>
            </div>

            <% if ("1".equals(request.getParameter("privateBlocked"))) { %>
                <div style="background:#fff7ed;color:#92400e;border:1px solid #fed7aa;
                            border-radius:8px;padding:0.55rem 0.8rem;font-size:0.85rem;margin-bottom:0.75rem;">
                    That group is private. Join it first to view the details.
                </div>
            <% } %>

            <% String error = (String) request.getAttribute("error");
               if (error != null) { %>
                <p style="color:red;font-size:0.85rem;margin:0;"><%= error %></p>
            <% } %>

            <% if (results.isEmpty()) { %>
                <p style="color:var(--sm-text-muted);font-size:0.875rem;margin:0;">No groups found. Try adjusting your filters.</p>
            <% } else {
                for (Map<String, String> g : results) {
                    boolean isFull   = "0 spots left".equals(g.get("capacity"));
                    boolean isMember = "Member".equals(g.get("memberStatus"));
                    boolean isPrivate = "Private".equals(g.get("status"));
            %>
                <div style="display:flex;align-items:center;justify-content:space-between;
                            gap:0.75rem;padding:0.6rem 0;
                            border-bottom:1px solid var(--sm-border,#e5e7eb);">
                    <div style="min-width:0;flex:1;">
                        <div style="display:flex;align-items:center;gap:0.4rem;flex-wrap:wrap;">
                            <a href="groupDetail.jsp?groupId=<%= g.get("groupId") %>"
                               style="font-weight:600;font-size:0.92rem;color:var(--sm-text);
                                      text-decoration:none;"
                               onmouseover="this.style.color='var(--sm-primary)'"
                               onmouseout="this.style.color='var(--sm-text)'">
                                <%= g.get("name") %>
                            </a>
                            <span style="background:#eff6ff;color:#1d4ed8;border:1px solid #bfdbfe;
                                         border-radius:99px;padding:0.1rem 0.45rem;font-size:0.7rem;
                                         font-weight:600;white-space:nowrap;">#<%= g.get("groupId") %></span>
                            <% if (isPrivate) { %><span title="Passcode required" style="font-size:0.8rem;">🔒</span><% } %>
                        </div>
                        <div style="font-size:0.78rem;color:var(--sm-text-muted);margin-top:0.15rem;">
                            <%= g.get("course") %>
                            &nbsp;&middot;&nbsp;<%= g.get("modality") %>
                            <% if (g.get("location") != null && !g.get("location").isEmpty()) { %>
                                &nbsp;&middot;&nbsp;<%= g.get("location") %>
                            <% } %>
                            &nbsp;&middot;&nbsp;<%= g.get("capacity") %>
                        </div>
                    </div>
                    <div style="flex-shrink:0;">
                        <% if (isMember) { %>
                            <span style="font-size:0.78rem;color:#15803d;font-weight:500;">&#10003; Joined</span>
                        <% } else if (isFull) { %>
                            <span style="font-size:0.78rem;color:var(--sm-text-muted);">Full</span>
                        <% } else { %>
                            <a href="joinGroup.jsp?groupId=<%= g.get("groupId") %>"
                               class="sm-btn sm-btn-primary"
                               style="font-size:0.78rem;padding:0.25rem 0.75rem;">Join</a>
                        <% } %>
                    </div>
                </div>
            <% } } %>

        </div>
    </div>
    <% } %>
</main>

</body>
</html>