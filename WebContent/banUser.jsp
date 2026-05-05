<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    if (!"Admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String userIdParam = request.getParameter("userId");
    if (userIdParam == null || userIdParam.isBlank()) {
        response.sendRedirect("adminUsers.jsp");
        return;
    }

    int targetId = Integer.parseInt(userIdParam);
    int currentAdminId = (Integer) session.getAttribute("userId");

    if (targetId == currentAdminId) {
        response.sendRedirect("adminUsers.jsp?error=self");
        return;
    }

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu")) {

            // Prevent banning another admin
            PreparedStatement check = conn.prepareStatement(
                "SELECT user_id FROM Administrator WHERE user_id = ?"
            );
            check.setInt(1, targetId);
            ResultSet rs = check.executeQuery();
            if (rs.next()) {
                rs.close();
                check.close();
                response.sendRedirect("adminUsers.jsp?error=protected");
                return;
            }
            rs.close();
            check.close();

            PreparedStatement ps = conn.prepareStatement(
                "UPDATE User SET is_banned = TRUE WHERE user_id = ?"
            );
            ps.setInt(1, targetId);
            ps.executeUpdate();
            ps.close();
        }
    } catch (Exception e) {
        response.sendRedirect("adminUsers.jsp?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        return;
    }

    response.sendRedirect("adminUsers.jsp");
%>
