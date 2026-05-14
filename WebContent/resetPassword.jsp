<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.security.*, java.nio.charset.*" %>

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
%>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");
    int    userId   = (Integer) session.getAttribute("userId");
    boolean forcedChange = Boolean.TRUE.equals(session.getAttribute("mustChangePassword"));

    String error   = null;
    String success = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String currentPassword = request.getParameter("currentPassword");
        String newPassword     = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (currentPassword == null || currentPassword.isBlank() ||
            newPassword     == null || newPassword.isBlank() ||
            confirmPassword == null || confirmPassword.isBlank()) {
            error = "All fields are required.";
        } else if (newPassword.length() < 8) {
            error = "New password must be at least 8 characters.";
        } else if (!newPassword.equals(confirmPassword)) {
            error = "New password and confirmation do not match.";
        } else if (newPassword.equals(currentPassword)) {
            error = "New password must be different from your current password.";
        } else {
            String currentHash = hashPassword(currentPassword);
            String newHash     = hashPassword(newPassword);
            if (currentHash == null || newHash == null) {
                error = "Server error, please try again.";
            } else {
                Connection conn = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

                    ps = conn.prepareStatement(
                        "SELECT password_hash FROM User WHERE user_id = ?");
                    ps.setInt(1, userId);
                    rs = ps.executeQuery();

                    if (!rs.next()) {
                        error = "Account not found.";
                    } else if (!currentHash.equals(rs.getString("password_hash"))) {
                        error = "Current password is incorrect.";
                    } else {
                        rs.close(); ps.close();
                        ps = conn.prepareStatement(
                            "UPDATE User SET password_hash = ?, must_change_password = FALSE WHERE user_id = ?");
                        ps.setString(1, newHash);
                        ps.setInt(2, userId);
                        ps.executeUpdate();
                        session.removeAttribute("mustChangePassword");
                        forcedChange = false;
                        success = "Your password has been updated.";
                    }
                } catch (Exception e) {
                    error = "Database error: " + e.getMessage();
                } finally {
                    if (rs   != null) try { rs.close();   } catch (SQLException ignored) {}
                    if (ps   != null) try { ps.close();   } catch (SQLException ignored) {}
                    if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
                }
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Change Password – StudyMatch</title>
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
            <% if (!forcedChange) { %>
                <a href="dashboard.jsp" class="sm-btn sm-btn-outline">Back to Dashboard</a>
            <% } %>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label">Account</div>
            <h2 style="margin:0 0 0.4rem;">Change your password</h2>
            <p>Enter your current password and choose a new one (at least 8 characters).</p>

            <% if (forcedChange) { %>
                <div style="background:#fef9c3;color:#854d0e;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    An administrator issued you a temporary password. You must set a new password before continuing.
                </div>
            <% } %>

            <% if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <% if (success != null) { %>
                <div style="background:#dcfce7;color:#166534;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= success %>
                </div>
            <% } %>

            <form action="resetPassword.jsp" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

                <div class="sm-field-group">
                    <label for="currentPassword">Current password</label>
                    <input id="currentPassword" class="sm-input" type="password" name="currentPassword" required>
                </div>

                <div class="sm-field-group">
                    <label for="newPassword">New password</label>
                    <input id="newPassword" class="sm-input" type="password" name="newPassword" minlength="8" required>
                </div>

                <div class="sm-field-group">
                    <label for="confirmPassword">Confirm new password</label>
                    <input id="confirmPassword" class="sm-input" type="password" name="confirmPassword" minlength="8" required>
                </div>

                <button type="submit" class="sm-btn sm-btn-primary sm-full-width">
                    Update password
                </button>
            </form>

            <% if (!forcedChange) { %>
                <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                    <a href="dashboard.jsp" style="color:var(--sm-primary);">Back to dashboard</a>
                </p>
            <% } %>

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
