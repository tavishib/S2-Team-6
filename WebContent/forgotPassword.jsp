<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Forgot Password – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="login.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
            <span>course-based study groups</span>
        </a>
        <nav class="sm-nav">
            <a href="login.jsp" class="sm-btn sm-btn-outline">Back to login</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label">Account recovery</div>
            <h2 style="margin:0 0 0.4rem;">Forgot your password?</h2>
            <p>StudyMatch does not yet support self-serve password reset by email.</p>

            <div style="background:#f3f4f6;border-radius:10px;padding:0.85rem 1rem;margin:1rem 0;font-size:0.9rem;line-height:1.6;color:var(--sm-text);">
                Email a StudyMatch administrator at
                <a href="mailto:admin@sjsu.edu" style="color:var(--sm-primary);font-weight:600;">admin@sjsu.edu</a>
                from your SJSU email and request a password reset. An admin will issue you a one-time temporary password.
            </div>

            <p style="font-size:0.875rem;color:var(--sm-text-muted);">
                After you log in with the temporary password, you will be required to choose a new one before you can access your account.
            </p>

            <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                <a href="login.jsp" style="color:var(--sm-primary);">Back to login</a>
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
