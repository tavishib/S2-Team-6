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
    <title>Dashboard – StudyMatch</title>
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

            <%-- Settings dropdown --%>
            <div id="settingsMenu" style="position:relative;display:inline-block;">
                <button id="settingsBtn" title="Settings"
                        style="background:none;border:1px solid var(--sm-border,#e5e7eb);
                               border-radius:8px;padding:0.35rem 0.55rem;cursor:pointer;
                               display:flex;align-items:center;color:var(--sm-text-muted);">
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"
                         viewBox="0 0 24 24" fill="none" stroke="currentColor"
                         stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="3"/>
                        <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06
                                 a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09
                                 A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83
                                 l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09
                                 A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83
                                 l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09
                                 a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83
                                 l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09
                                 a1.65 1.65 0 0 0-1.51 1z"/>
                    </svg>
                </button>
                <div id="settingsDropdown"
                     style="display:none;position:absolute;right:0;top:calc(100% + 6px);
                            min-width:180px;background:#fff;border:1px solid var(--sm-border,#e5e7eb);
                            border-radius:10px;box-shadow:0 4px 16px rgba(0,0,0,0.10);
                            overflow:hidden;z-index:100;">
                    <a href="deleteAccount"
                       style="display:block;padding:0.65rem 1rem;font-size:0.875rem;
                              color:#dc2626;text-decoration:none;font-weight:500;"
                       onmouseover="this.style.background='#fff1f1'"
                       onmouseout="this.style.background='transparent'">
                        Delete account
                    </a>
                </div>
            </div>

            <a href="logout" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
    <section class="sm-dashboard">
        <div class="sm-container sm-dashboard-grid">

            <div class="sm-dashboard-main">
                <div class="sm-small-label">Dashboard</div>
                <h1>Welcome back, <%= userName %>!</h1>
                <p>Quickly find or create a study group for your courses.
                   Keep everything organized in one simple place.</p>

                <div class="sm-dashboard-actions">
                    <a href="#quick-search" class="sm-btn sm-btn-primary">Find a study group</a>
                    <a href="createGroup.jsp" class="sm-btn sm-btn-secondary">Create a study group</a>
					<a href="createCourse.jsp" class="sm-btn sm-btn-secondary">Create a course</a>          
				</div>

                <div class="sm-quick-links">
                    <div class="sm-quick-link">
                        <span>My groups</span>
                        Groups you've joined or created.
                    </div>
                    <div class="sm-quick-link">
                        <span>Upcoming sessions</span>
                        See what's scheduled this week.
                    </div>
                    <div class="sm-quick-link">
                        <span>Explore courses</span>
                        Browse groups by course ID.
                    </div>
                </div>
            </div>

            <aside class="sm-dashboard-side sm-quick-card" id="quick-search">
                <div class="sm-small-label">Quick search</div>
                <h2>Search study groups</h2>
                <p>Filter by course, meeting type and focus.</p>

                <form id="quickSearchForm" action="SearchGroups" method="get">
                    <div class="sm-field-group">
                        <label for="courseId">Course ID</label>
                        <input id="courseId" class="sm-input" type="text" name="courseId"
                               placeholder="e.g. CS157A">
                    </div>

                    <div class="sm-field-group">
                        <label for="meetingType">Meeting type</label>
                        <select id="meetingType" class="sm-select" name="meetingType">
                            <option value="">Any</option>
                            <option value="Online">Online</option>
                            <option value="In-Person">In‑Person</option>
                            <option value="Hybrid">Hybrid</option>
                        </select>
                    </div>

                    <div class="sm-field-group">
                        <label for="tag">Focus</label>
                        <select id="tag" class="sm-select" name="tag">
                            <option value="">Any</option>
                            <option value="Homework">Homework</option>
                            <option value="Exam Prep">Exam Prep</option>
                            <option value="Project">Project</option>
                        </select>
                    </div>

                    <button type="submit" class="sm-btn sm-btn-primary sm-full-width">
                        Search groups
                    </button>
                </form>

                <p class="sm-card-note">
                    You can refine results later by time, size, and location.
                </p>

            </aside>

        </div>
    </section>
</main>

<footer class="sm-footer">
    <div class="sm-container sm-footer-content">
        <span>© <%= java.time.Year.now() %> StudyMatch</span>
        <span>Built for collaborative learning in higher education.</span>
    </div>
</footer>

<script src="js/main.js"></script>
<script>
    window.addEventListener('pageshow', function(event) {
        if (event.persisted) {
            window.location.replace('login.jsp');
        }
    });
</script>
<script>
    // Settings dropdown toggle
    const settingsBtn      = document.getElementById("settingsBtn");
    const settingsDropdown = document.getElementById("settingsDropdown");

    settingsBtn.addEventListener("click", function (e) {
        e.stopPropagation();
        const isOpen = settingsDropdown.style.display === "block";
        settingsDropdown.style.display = isOpen ? "none" : "block";
    });

    document.addEventListener("click", function () {
        settingsDropdown.style.display = "none";
    });

    // Inactivity timer
    let inactivityTimer;

    function resetTimer() {
        clearTimeout(inactivityTimer);
        inactivityTimer = setTimeout(() => {
            window.location.href = "logout?timeout=true";
        }, 900000);
    }

    ["mousemove", "keydown", "click", "scroll"].forEach(evt =>
        document.addEventListener(evt, resetTimer)
    );

    resetTimer();
</script>

</body>
</html>
