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
    if (session != null && session.getAttribute("userId") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
    }

    String error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.isBlank() || password.isBlank()) {
            error = "Email and password are required.";
        } else {
            String passwordHash = hashPassword(password);
            if (passwordHash == null) {
                error = "Server error, please try again.";
            } else {
                Connection conn = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch", "root", "mysql@1234");

                    ps = conn.prepareStatement(
                        "SELECT u.user_id, u.name, u.email, u.password_hash, s.major, a.admin_level " +
                        "FROM User u " +
                        "LEFT JOIN Student s ON u.user_id = s.user_id " +
                        "LEFT JOIN Administrator a ON u.user_id = a.user_id " +
                        "WHERE u.email = ?"
                    );
                    ps.setString(1, email.toLowerCase().trim());
                    rs = ps.executeQuery();

                    if (!rs.next()) {
                        error = "Invalid email or password.";
                    } else if (!rs.getString("password_hash").equals(passwordHash)) {
                        error = "Invalid email or password.";
                    } else {
                        HttpSession sess = request.getSession(true);
                        sess.setMaxInactiveInterval(15 * 60);
                        sess.setAttribute("userId",    rs.getInt("user_id"));
                        sess.setAttribute("userName",  rs.getString("name"));
                        sess.setAttribute("userEmail", rs.getString("email"));

                        String major = rs.getString("major");
                        if (major != null) {
                            sess.setAttribute("role",  "Student");
                            sess.setAttribute("major", major);
                        } else {
                            sess.setAttribute("role",       "Admin");
                            sess.setAttribute("adminLevel", rs.getInt("admin_level"));
                        }
                        response.sendRedirect("dashboard.jsp");
                        return;
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
    <title>Log In – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="index.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
            <span>course-based study groups</span>
        </a>
        <nav class="sm-nav">
            <a href="signup.jsp" class="sm-btn sm-btn-outline">Sign up</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label">Welcome back</div>
            <h2 style="margin:0 0 0.4rem;">Log in to StudyMatch</h2>
            <p>Enter your SJSU credentials to continue.</p>

            <% if ("true".equals(request.getParameter("deleted"))) { %>
                <div style="background:#dcfce7;color:#166534;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    Your account has been permanently deleted.
                </div>
            <% } %>

            <% if ("true".equals(request.getParameter("registered"))) { %>
                <div style="background:#dcfce7;color:#166534;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    Account created successfully! You can now log in.
                </div>
            <% } %>

            <% if ("true".equals(request.getParameter("timeout"))) { %>
                <div style="background:#fef9c3;color:#854d0e;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    Your session expired due to inactivity. Please log in again.
                </div>
            <% } %>

            <% if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form action="login.jsp" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

                <div class="sm-field-group">
                    <label for="email">SJSU email</label>
                    <input id="email" class="sm-input" type="email" name="email"
                           placeholder="yourname@sjsu.edu" required>
                </div>

                <div class="sm-field-group">
                    <label for="password">Password</label>
                    <input id="password" class="sm-input" type="password" name="password"
                           placeholder="Your password" required>
                </div>

                <button type="submit" class="sm-btn sm-btn-primary sm-full-width" style="margin-top:0.25rem;">
                    Log in
                </button>

            </form>

            <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                Don't have an account? <a href="signup.jsp" style="color:var(--sm-primary);">Sign up</a>
            </p>

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
