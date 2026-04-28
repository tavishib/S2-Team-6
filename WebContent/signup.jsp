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
        String name     = request.getParameter("name");
        String email    = request.getParameter("email");
        String password = request.getParameter("password");
        String major    = request.getParameter("major");

        if (name == null || name.isBlank() || email == null || email.isBlank() ||
            password == null || password.isBlank() || major == null || major.isBlank()) {
            error = "All fields are required.";
        } else if (!email.toLowerCase().endsWith("@sjsu.edu")) {
            error = "Email must be a valid SJSU email address (e.g. yourname@sjsu.edu).";
        } else if (password.length() < 8) {
            error = "Password must be at least 8 characters.";
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
                    conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

                    // Check for duplicate email
                    ps = conn.prepareStatement("SELECT user_id FROM User WHERE email = ?");
                    ps.setString(1, email.toLowerCase().trim());
                    rs = ps.executeQuery();
                    if (rs.next()) {
                        error = "An account with that email already exists.";
                    } else {
                        rs.close(); ps.close();

                        // Insert into User
                        ps = conn.prepareStatement(
                            "INSERT INTO User (name, email, password_hash) VALUES (?, ?, ?)",
                            PreparedStatement.RETURN_GENERATED_KEYS
                        );
                        ps.setString(1, name.trim());
                        ps.setString(2, email.toLowerCase().trim());
                        ps.setString(3, passwordHash);
                        ps.executeUpdate();

                        rs = ps.getGeneratedKeys();
                        if (!rs.next()) {
                            error = "Could not create account. Please try again.";
                        } else {
                            int userId = rs.getInt(1);
                            rs.close(); ps.close();

                            // Insert into Student
                            ps = conn.prepareStatement("INSERT INTO Student (user_id, major) VALUES (?, ?)");
                            ps.setInt(1, userId);
                            ps.setString(2, major.trim());
                            ps.executeUpdate();

                            response.sendRedirect("login.jsp?registered=true");
                            return;
                        }
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
    <title>Sign Up – StudyMatch</title>
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
            <a href="login.jsp">Log in</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label">Get started</div>
            <h2 style="margin:0 0 0.4rem;">Create your account</h2>
            <p>SJSU students only. Use your @sjsu.edu email to register.</p>

            <% if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form action="signup.jsp" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

                <div class="sm-field-group">
                    <label for="name">Full name</label>
                    <input id="name" class="sm-input" type="text" name="name"
                           placeholder="e.g. Jane Smith" required>
                </div>

                <div class="sm-field-group">
                    <label for="email">SJSU email</label>
                    <input id="email" class="sm-input" type="email" name="email"
                           placeholder="yourname@sjsu.edu" required>
                </div>

                <div class="sm-field-group">
                    <label for="password">Password</label>
                    <input id="password" class="sm-input" type="password" name="password"
                           placeholder="Min. 8 characters" required minlength="8">
                </div>

                <div class="sm-field-group">
                    <label for="major">Major</label>
                    <input id="major" class="sm-input" type="text" name="major"
                           placeholder="e.g. Computer Science" required>
                </div>

                <button type="submit" class="sm-btn sm-btn-primary sm-full-width" style="margin-top:0.25rem;">
                    Create account
                </button>

            </form>

            <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                Already have an account? <a href="login.jsp" style="color:var(--sm-primary);">Log in</a>
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
