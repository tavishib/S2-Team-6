<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int userId = (int) session.getAttribute("userId");
    String groupIdStr = request.getParameter("groupId");

    if (groupIdStr == null) {
        response.sendRedirect("searchGroups.jsp");
        return;
    }

    int groupId = Integer.parseInt(groupIdStr);

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu")) {

            // Check if already a member
            PreparedStatement check = conn.prepareStatement(
                "SELECT 1 FROM Membership WHERE user_id = ? AND group_id = ?");
            check.setInt(1, userId);
            check.setInt(2, groupId);
            ResultSet rs = check.executeQuery();

            if (!rs.next()) {
                // Check capacity
                PreparedStatement capCheck = conn.prepareStatement(
                    "SELECT sg.max_capacity, COUNT(m.user_id) AS current_members " +
                    "FROM Study_Group sg LEFT JOIN Membership m ON sg.group_id = m.group_id " +
                    "WHERE sg.group_id = ? GROUP BY sg.group_id");
                capCheck.setInt(1, groupId);
                ResultSet capRs = capCheck.executeQuery();

                if (capRs.next()) {
                    int max = capRs.getInt("max_capacity");
                    int curr = capRs.getInt("current_members");

                    if (curr < max) {
                        PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO Membership (user_id, group_id, joined_at, membership_role, membership_status) " +
                            "VALUES (?, ?, NOW(), 'Member', 'Active')");
                        ps.setInt(1, userId);
                        ps.setInt(2, groupId);
                        ps.executeUpdate();
                    } else {
                        session.setAttribute("flashError", "Group is full.");
                    }
                }
            } else {
                session.setAttribute("flashError", "You are already a member.");
            }
        }
    } catch (Exception e) {
        session.setAttribute("flashError", e.getMessage());
    }

    response.sendRedirect("searchGroups.jsp");
%>