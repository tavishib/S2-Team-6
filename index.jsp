<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>StudyMatch – Find Your Perfect Study Group</title>
    <link rel="stylesheet" href="css/styles.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
<header class="sm-header">
    <div class="sm-container sm-header-content">
        <div class="sm-logo">
            StudyMatch
            <span>course-based study groups</span>
        </div>
        <nav class="sm-nav">
            <a href="login.jsp">Log in</a>
            <a href="signup.jsp" class="sm-btn sm-btn-outline">Sign up</a>
        </nav>
    </div>
</header>

<main>
    <section class="sm-dashboard">
        <div class="sm-container sm-dashboard-grid">
            <!-- Dashboard main (for logged-in feel) -->
            <div class="sm-dashboard-main">
                <div class="sm-small-label">Dashboard</div>
                <h1>Welcome to StudyMatch</h1>
                <p>
                    Quickly find or create a study group for your courses.
                    Keep everything organised in one simple place.
                </p>

                <div class="sm-dashboard-actions">
                    <a href="#quick-search" class="sm-btn sm-btn-primary">Find a study group</a>
                    <a href="createGroup.jsp" class="sm-btn sm-btn-secondary">Create a study group</a>
                </div>

                <div class="sm-quick-links">
                    <div class="sm-quick-link">
                        <span>My groups</span>
                        Groups you’ve joined or created.
                    </div>
                    <div class="sm-quick-link">
                        <span>Upcoming sessions</span>
                        See what’s scheduled this week.
                    </div>
                    <div class="sm-quick-link">
                        <span>Explore courses</span>
                        Browse groups by course ID.
                    </div>
                </div>
            </div>

            <!-- Side: Quick search -->
            <aside class="sm-dashboard-side sm-quick-card" id="quick-search">
                <div class="sm-small-label">Quick search</div>
                <h2>Search study groups</h2>
                <p>Filter by course, meeting type and focus.</p>

                <form id="quickSearchForm" action="SearchGroups" method="get">
                    <div class="sm-field-group">
                        <label for="courseId">Course ID</label>
                        <input id="courseId"
                               class="sm-input"
                               type="text"
                               name="courseId"
                               placeholder="e.g. CS101">
                    </div>

                    <div class="sm-field-group">
                        <label for="meetingType">Meeting type</label>
                        <select id="meetingType" class="sm-select" name="meetingType">
                            <option value="">Any</option>
                            <option value="remote">Remote</option>
                            <option value="in-person">In‑person</option>
                        </select>
                    </div>

                    <div class="sm-field-group">
                        <label for="tag">Focus</label>
                        <select id="tag" class="sm-select" name="tag">
                            <option value="">Any</option>
                            <option value="homework">Homework</option>
                            <option value="exam prep">Exam prep</option>
                            <option value="project">Project</option>
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
</body>
</html>