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
        response.sendRedirect("dashboard.jsp");
        return;
    }

    int groupId = Integer.parseInt(groupIdStr);

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu")) {

            // Don't allow leader to leave (they must delete the group instead)
            PreparedStatement roleCheck = conn.prepareStatement(
                "SELECT membership_role FROM Membership WHERE user_id = ? AND group_id = ?");
            roleCheck.setInt(1, userId);
            roleCheck.setInt(2, groupId);
            ResultSet rs = roleCheck.executeQuery();

            if (rs.next() && "Leader".equals(rs.getString("membership_role"))) {
                session.setAttribute("flashError", "Leaders cannot leave. Delete the group instead.");
            } else {
                PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Membership WHERE user_id = ? AND group_id = ?");
                ps.setInt(1, userId);
                ps.setInt(2, groupId);
                ps.executeUpdate();
            }
        }
    } catch (Exception e) {
        session.setAttribute("flashError", e.getMessage());
    }

    response.sendRedirect("dashboard.jsp");
%>