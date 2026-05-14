<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // Auth check
    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // Admin check
    if (!"Admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String courseIdParam = request.getParameter("courseId");
    if (courseIdParam == null || courseIdParam.isBlank()) {
        response.sendRedirect("listCourses.jsp");
        return;
    }
    String courseId = courseIdParam.trim();

    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        // Defensive check: block deletion if any study group references this course.
        // The UI in listCourses.jsp should already prevent this, but a direct hit
        // to this URL must not silently fall through to a FK error.
        PreparedStatement check = conn.prepareStatement(
            "SELECT COUNT(*) FROM Study_Group WHERE course_id = ?");
        check.setString(1, courseId);
        ResultSet rs = check.executeQuery();
        rs.next();
        int groupCount = rs.getInt(1);
        rs.close(); check.close();

        if (groupCount > 0) {
            conn.close();
            response.sendRedirect("listCourses.jsp?error=hasGroups&courseId="
                + java.net.URLEncoder.encode(courseId, "UTF-8"));
            return;
        }

        PreparedStatement ps = conn.prepareStatement(
            "DELETE FROM Course WHERE course_id = ?");
        ps.setString(1, courseId);
        int rows = ps.executeUpdate();
        ps.close();
        conn.close();

        if (rows == 0) {
            response.sendRedirect("listCourses.jsp?error=notFound&courseId="
                + java.net.URLEncoder.encode(courseId, "UTF-8"));
            return;
        }

        response.sendRedirect("listCourses.jsp?deleted="
            + java.net.URLEncoder.encode(courseId, "UTF-8"));

    } catch (Exception e) {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        response.sendRedirect("listCourses.jsp?error=db");
    }
%>
