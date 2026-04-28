<%@ page contentType="text/html; charset=UTF-8" language="java" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String userName = (String) session.getAttribute("userName");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Delete Account – StudyMatch</title>
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
            <a href="logout" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <div class="sm-container" style="max-width:480px; margin-top:2.5rem;">
        <div class="sm-dashboard-side sm-quick-card">

            <div class="sm-small-label" style="color:#dc2626;">Danger zone</div>
            <h2 style="margin:0 0 0.4rem;">Delete your account</h2>
            <p>This action is <strong>permanent</strong> and cannot be undone. All of your data will be removed, including:</p>

            <ul style="font-size:0.9rem;color:var(--sm-text-muted);margin:0 0 1.25rem 1.2rem;line-height:1.8;">
                <li>Your profile and account credentials</li>
                <li>Study groups you lead (and their memberships, messages, and schedules)</li>
                <li>Your memberships in other groups</li>
                <li>Messages and replies you have posted</li>
            </ul>

            <%-- Error message from JSP logic --%>
            <% String error = (String) request.getAttribute("error");
               if (error != null) { %>
                <div style="background:#fee2e2;color:#991b1b;border-radius:8px;padding:0.6rem 0.8rem;font-size:0.875rem;margin-bottom:0.8rem;">
                    <%= error %>
                </div>
            <% } %>

            <form id="deleteForm" method="post" action="deleteAccount">
                <button type="button" id="deleteBtn"
                        class="sm-btn sm-full-width"
                        style="background:#dc2626;color:#fff;border:none;cursor:pointer;
                               padding:0.65rem 1rem;border-radius:8px;font-size:0.95rem;
                               font-weight:600;">
                    Delete my account
                </button>
            </form>

            <p class="sm-card-note" style="text-align:center;margin-top:1rem;">
                Changed your mind? <a href="dashboard.jsp" style="color:var(--sm-primary);">Go back to dashboard</a>
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

<script>
    document.getElementById("deleteBtn").addEventListener("click", function () {
        if (confirm("Are you sure you want to permanently delete your account?\nThis cannot be undone.")) {
            document.getElementById("deleteForm").submit();
        }
    });
</script>

</body>
</html>
