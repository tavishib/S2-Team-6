<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>

<%
    // Auth check
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int currentUserId = (Integer) session.getAttribute("userId");
    boolean isAdmin   = "Admin".equals(session.getAttribute("role"));
    boolean fromAdmin = "admin".equals(request.getParameter("from"));

    // Admin-context deletes return to adminGroups.jsp; leader deletes return to dashboard.
    String successUrl = (isAdmin && fromAdmin) ? "adminGroups.jsp" : "dashboard.jsp";

    String groupIdParam = request.getParameter("groupId");
    if (groupIdParam == null || groupIdParam.isEmpty()) {
        response.sendRedirect(successUrl);
        return;
    }
    int groupId = Integer.parseInt(groupIdParam);

    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        // Verify the current user is either the group's leader or an admin.
        PreparedStatement check = conn.prepareStatement(
            "SELECT leader_id FROM Study_Group WHERE group_id = ?");
        check.setInt(1, groupId);
        ResultSet rs = check.executeQuery();

        if (!rs.next() || (!isAdmin && rs.getInt("leader_id") != currentUserId)) {
            rs.close(); check.close(); conn.close();
            response.sendRedirect(successUrl);
            return;
        }
        rs.close(); check.close();

        // Delete in correct order (child tables first)
        PreparedStatement ps;

        // 1. Delete replies to messages in this group
        ps = conn.prepareStatement(
            "DELETE FROM Reply WHERE message_id IN " +
            "(SELECT message_id FROM Message WHERE group_id = ?)");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        // 2. Delete messages
        ps = conn.prepareStatement("DELETE FROM Message WHERE group_id = ?");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        // 3. Delete memberships
        ps = conn.prepareStatement("DELETE FROM Membership WHERE group_id = ?");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        // 4. Delete meeting schedules
        ps = conn.prepareStatement("DELETE FROM Meeting_Schedule WHERE group_id = ?");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        // 5. Delete group tags
        ps = conn.prepareStatement("DELETE FROM Group_Tag WHERE group_id = ?");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        // 6. Finally delete the group itself
        ps = conn.prepareStatement("DELETE FROM Study_Group WHERE group_id = ?");
        ps.setInt(1, groupId);
        ps.executeUpdate(); ps.close();

        conn.close();

        response.sendRedirect(successUrl + "?deleted=" + groupId);

    } catch (Exception e) {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        response.sendRedirect(successUrl + "?error=db");
    }
%>