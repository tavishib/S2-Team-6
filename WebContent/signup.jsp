<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
    if (session != null && session.getAttribute("userId") != null) {
        response.sendRedirect("dashboard.jsp");
        return;
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

            <% String error = (String) request.getAttribute("error");
               if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form action="signup" method="post" style="display:flex;flex-direction:column;gap:0.75rem;">

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
