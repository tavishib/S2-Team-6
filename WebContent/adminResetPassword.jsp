<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.security.*, java.nio.charset.*, java.security.SecureRandom" %>

<%!
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            return null;
        }
    }

    // Generate a 10-char temp password from an unambiguous alphabet (no 0/O/1/l).
    private String generateTempPassword() {
        String alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
        SecureRandom rng = new SecureRandom();
        StringBuilder sb = new StringBuilder("Tmp-");
        for (int i = 0; i < 8; i++) {
            sb.append(alphabet.charAt(rng.nextInt(alphabet.length())));
        }
        return sb.toString();
    }
%>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    if (!"Admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    int currentAdminId = (Integer) session.getAttribute("userId");

    String userIdParam = request.getParameter("userId");
    if (userIdParam == null || userIdParam.isBlank()) {
        response.sendRedirect("adminUsers.jsp");
        return;
    }

    int targetUserId;
    try {
        targetUserId = Integer.parseInt(userIdParam.trim());
    } catch (NumberFormatException e) {
        response.sendRedirect("adminUsers.jsp");
        return;
    }

    if (targetUserId == currentAdminId) {
        // An admin must use the in-session resetPassword.jsp flow on themselves.
        response.sendRedirect("adminUsers.jsp?error=selfReset");
        return;
    }

    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        // Verify the target exists and is not an admin.
        ps = conn.prepareStatement(
            "SELECT u.name, a.user_id AS admin_id " +
            "FROM User u LEFT JOIN Administrator a ON u.user_id = a.user_id " +
            "WHERE u.user_id = ?");
        ps.setInt(1, targetUserId);
        rs = ps.executeQuery();
        if (!rs.next()) {
            response.sendRedirect("adminUsers.jsp?error=notFound");
            return;
        }
        if (rs.getObject("admin_id") != null) {
            response.sendRedirect("adminUsers.jsp?error=adminProtected");
            return;
        }
        String targetName = rs.getString("name");
        rs.close(); ps.close();

        String tempPlain = generateTempPassword();
        String tempHash  = hashPassword(tempPlain);
        if (tempHash == null) {
            response.sendRedirect("adminUsers.jsp?error=db");
            return;
        }

        ps = conn.prepareStatement(
            "UPDATE User SET password_hash = ?, must_change_password = TRUE WHERE user_id = ?");
        ps.setString(1, tempHash);
        ps.setInt(2, targetUserId);
        ps.executeUpdate();

        String enc = java.net.URLEncoder.encode(tempPlain, "UTF-8")
                   + "&userName=" + java.net.URLEncoder.encode(targetName != null ? targetName : "", "UTF-8");
        response.sendRedirect("adminUsers.jsp?reset=" + targetUserId + "&temp=" + enc);

    } catch (Exception e) {
        response.sendRedirect("adminUsers.jsp?error=db");
    } finally {
        if (rs   != null) try { rs.close();   } catch (SQLException ignored) {}
        if (ps   != null) try { ps.close();   } catch (SQLException ignored) {}
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }
%>
