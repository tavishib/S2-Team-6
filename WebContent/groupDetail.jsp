<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.text.SimpleDateFormat" %>

<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    if (session == null || session.getAttribute("userId") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    int currentUserId = (Integer) session.getAttribute("userId");
    String userName   = (String)  session.getAttribute("userName");

    String groupIdParam = request.getParameter("groupId");
    if (groupIdParam == null || groupIdParam.isEmpty()) {
        response.sendRedirect("searchGroups.jsp");
        return;
    }
    int groupId = Integer.parseInt(groupIdParam);

    String postError   = null;
    String postSuccess = null;

    // ── Handle POST (new message or new reply) ────────────────────────────────
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action      = request.getParameter("action");
        String messageText = request.getParameter("messageText");
        String replyText   = request.getParameter("replyText");
        String msgIdParam  = request.getParameter("messageId");

        Connection conn = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

            if ("postMessage".equals(action) && messageText != null && !messageText.trim().isEmpty()) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Message (group_id, user_id, message_text, posted_at) VALUES (?, ?, ?, NOW())");
                ps.setInt(1, groupId);
                ps.setInt(2, currentUserId);
                ps.setString(3, messageText.trim());
                ps.executeUpdate();
                ps.close();
                postSuccess = "Message posted.";

            } else if ("postReply".equals(action) && replyText != null && !replyText.trim().isEmpty()
                       && msgIdParam != null) {
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO Reply (message_id, user_id, reply_text, posted_at) VALUES (?, ?, ?, NOW())");
                ps.setInt(1, Integer.parseInt(msgIdParam));
                ps.setInt(2, currentUserId);
                ps.setString(3, replyText.trim());
                ps.executeUpdate();
                ps.close();
                postSuccess = "Reply posted.";
            }
        } catch (Exception e) {
            postError = "Error: " + e.getMessage();
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
        }
        response.sendRedirect("groupDetail.jsp?groupId=" + groupId
            + (postSuccess != null ? "&posted=1" : ""));
        return;
    }

    boolean justPosted = "1".equals(request.getParameter("posted"));

    // ── Load all data ─────────────────────────────────────────────────────────
    String groupName = "", courseId = "", courseTitle = "", deptName = "",
           modality = "", location = "", status = "", description = "",
           leaderName = "";
    int maxCapacity = 0, memberCount = 0, leaderId = 0;

    // members
    java.util.List<String[]> members = new java.util.ArrayList<>();
    // schedules
    java.util.List<String[]> schedules = new java.util.ArrayList<>();
    // tags
    java.util.List<String> tags = new java.util.ArrayList<>();
    // messages: [messageId, authorName, text, postedAt]
    java.util.List<String[]> messages = new java.util.ArrayList<>();
    // replies keyed by messageId: list of [authorName, text, postedAt]
    java.util.Map<Integer, java.util.List<String[]>> replies = new java.util.LinkedHashMap<>();

    boolean isMember = false;
    String loadError = null;
    SimpleDateFormat dtFmt = new SimpleDateFormat("MMM d, yyyy 'at' h:mm a");
    SimpleDateFormat timeFmt = new SimpleDateFormat("h:mm a");

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/StudyMatch", "root", "CS157A@sjsu");

        // Group info
        PreparedStatement ps = conn.prepareStatement(
            "SELECT sg.group_id, sg.group_name, sg.course_id, sg.modality, sg.location, " +
            "sg.current_status, sg.max_capacity, sg.description, sg.leader_id, " +
            "u.name AS leader_name, c.title AS course_title, c.deptName, " +
            "COUNT(m.user_id) AS member_count " +
            "FROM Study_Group sg " +
            "JOIN User u ON sg.leader_id = u.user_id " +
            "JOIN Course c ON sg.course_id = c.course_id " +
            "LEFT JOIN Membership m ON sg.group_id = m.group_id AND m.membership_status = 'Active' " +
            "WHERE sg.group_id = ? " +
            "GROUP BY sg.group_id");
        ps.setInt(1, groupId);
        ResultSet rs = ps.executeQuery();
        if (!rs.next()) {
            conn.close();
            response.sendRedirect("searchGroups.jsp");
            return;
        }
        groupName   = rs.getString("group_name");
        courseId    = rs.getString("course_id");
        courseTitle = rs.getString("course_title");
        deptName    = rs.getString("deptName");
        modality    = rs.getString("modality");
        location    = rs.getString("location");
        status      = rs.getString("current_status");
        description = rs.getString("description") != null ? rs.getString("description") : "";
        leaderName  = rs.getString("leader_name");
        leaderId    = rs.getInt("leader_id");
        maxCapacity = rs.getInt("max_capacity");
        memberCount = rs.getInt("member_count");
        rs.close(); ps.close();

        // Is current user a member?
        ps = conn.prepareStatement(
            "SELECT 1 FROM Membership WHERE user_id = ? AND group_id = ? AND membership_status = 'Active'");
        ps.setInt(1, currentUserId);
        ps.setInt(2, groupId);
        rs = ps.executeQuery();
        isMember = rs.next();
        rs.close(); ps.close();

        // Members list
        ps = conn.prepareStatement(
            "SELECT u.name, s.major, m.membership_role, m.joined_at " +
            "FROM Membership m " +
            "JOIN User u ON m.user_id = u.user_id " +
            "JOIN Student s ON m.user_id = s.user_id " +
            "WHERE m.group_id = ? AND m.membership_status = 'Active' " +
            "ORDER BY FIELD(m.membership_role,'Leader','Co-Leader','Member'), m.joined_at ASC");
        ps.setInt(1, groupId);
        rs = ps.executeQuery();
        while (rs.next()) {
            members.add(new String[]{
                rs.getString("name"),
                rs.getString("major") != null ? rs.getString("major") : "",
                rs.getString("membership_role"),
                rs.getTimestamp("joined_at") != null
                    ? new SimpleDateFormat("MMM yyyy").format(rs.getTimestamp("joined_at")) : ""
            });
        }
        rs.close(); ps.close();

        // Meeting schedules
        ps = conn.prepareStatement(
            "SELECT meeting_day, start_time, end_time, location, meeting_type " +
            "FROM Meeting_Schedule WHERE group_id = ? " +
            "ORDER BY FIELD(meeting_day,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')");
        ps.setInt(1, groupId);
        rs = ps.executeQuery();
        while (rs.next()) {
            String st = rs.getTime("start_time") != null
                ? timeFmt.format(rs.getTime("start_time")) : "";
            String et = rs.getTime("end_time") != null
                ? timeFmt.format(rs.getTime("end_time")) : "";
            schedules.add(new String[]{
                rs.getString("meeting_day"),
                st, et,
                rs.getString("location") != null ? rs.getString("location") : "",
                rs.getString("meeting_type") != null ? rs.getString("meeting_type") : ""
            });
        }
        rs.close(); ps.close();

        // Tags
        ps = conn.prepareStatement(
            "SELECT t.tag_name FROM Tag t " +
            "JOIN Group_Tag gt ON t.tag_id = gt.tag_id WHERE gt.group_id = ?");
        ps.setInt(1, groupId);
        rs = ps.executeQuery();
        while (rs.next()) tags.add(rs.getString("tag_name"));
        rs.close(); ps.close();

        // Messages
        ps = conn.prepareStatement(
            "SELECT msg.message_id, msg.message_text, msg.posted_at, u.name AS author " +
            "FROM Message msg " +
            "JOIN User u ON msg.user_id = u.user_id " +
            "WHERE msg.group_id = ? ORDER BY msg.posted_at ASC");
        ps.setInt(1, groupId);
        rs = ps.executeQuery();
        while (rs.next()) {
            int mid = rs.getInt("message_id");
            messages.add(new String[]{
                String.valueOf(mid),
                rs.getString("author"),
                rs.getString("message_text"),
                rs.getTimestamp("posted_at") != null
                    ? dtFmt.format(rs.getTimestamp("posted_at")) : ""
            });
            replies.put(mid, new java.util.ArrayList<>());
        }
        rs.close(); ps.close();

        // Replies for all messages
        if (!messages.isEmpty()) {
            ps = conn.prepareStatement(
                "SELECT r.message_id, r.reply_text, r.posted_at, u.name AS author " +
                "FROM Reply r " +
                "JOIN User u ON r.user_id = u.user_id " +
                "WHERE r.message_id IN " +
                "(SELECT message_id FROM Message WHERE group_id = ?) " +
                "ORDER BY r.posted_at ASC");
            ps.setInt(1, groupId);
            rs = ps.executeQuery();
            while (rs.next()) {
                int mid = rs.getInt("message_id");
                if (replies.containsKey(mid)) {
                    replies.get(mid).add(new String[]{
                        rs.getString("author"),
                        rs.getString("reply_text"),
                        rs.getTimestamp("posted_at") != null
                            ? dtFmt.format(rs.getTimestamp("posted_at")) : ""
                    });
                }
            }
            rs.close(); ps.close();
        }

        conn.close();
    } catch (Exception e) {
        loadError = e.getMessage();
    }

    boolean canPost = isMember || (currentUserId == leaderId);
    int spotsLeft   = maxCapacity - memberCount;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title><%= groupName %> – StudyMatch</title>
    <link rel="stylesheet" href="css/styles.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        /* ── Group Detail page styles ─────────────────────────── */
        .gd-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.55fr) minmax(0, 1fr);
            gap: 1.5rem;
            align-items: flex-start;
            margin-top: 1.5rem;
        }
        .gd-card {
            background: var(--sm-surface);
            border: 1px solid var(--sm-border);
            border-radius: var(--sm-radius-lg);
            box-shadow: var(--sm-shadow-soft);
            padding: 1.4rem 1.6rem;
        }
        .gd-section-title {
            font-size: 0.75rem;
            font-weight: 600;
            letter-spacing: 0.1em;
            text-transform: uppercase;
            color: var(--sm-text-muted);
            margin: 0 0 0.9rem;
        }
        /* Meta pills */
        .gd-meta { display: flex; flex-wrap: wrap; gap: 0.45rem; margin: 0.75rem 0 0; }
        .gd-pill {
            display: inline-flex; align-items: center; gap: 0.3rem;
            padding: 0.25rem 0.7rem; border-radius: var(--sm-radius-full);
            font-size: 0.78rem; font-weight: 500; border: 1px solid transparent;
        }
        .gd-pill-blue   { background:#eff6ff; color:#1d4ed8; border-color:#bfdbfe; }
        .gd-pill-green  { background:#f0fdf4; color:#15803d; border-color:#bbf7d0; }
        .gd-pill-amber  { background:#fffbeb; color:#92400e; border-color:#fde68a; }
        .gd-pill-purple { background:#faf5ff; color:#7e22ce; border-color:#e9d5ff; }
        .gd-pill-red    { background:#fff1f2; color:#be123c; border-color:#fecdd3; }
        .gd-pill-gray   { background:#f3f4f6; color:#374151; border-color:#e5e7eb; }
        /* Members */
        .gd-member {
            display: flex; align-items: center; gap: 0.75rem;
            padding: 0.55rem 0; border-bottom: 1px solid var(--sm-border);
        }
        .gd-member:last-child { border-bottom: none; }
        .gd-avatar {
            width: 34px; height: 34px; border-radius: 50%;
            background: var(--sm-primary-soft); color: var(--sm-primary);
            display: flex; align-items: center; justify-content: center;
            font-weight: 700; font-size: 0.85rem; flex-shrink: 0;
        }
        .gd-member-info { flex: 1; min-width: 0; }
        .gd-member-name { font-weight: 500; font-size: 0.88rem; }
        .gd-member-sub  { font-size: 0.75rem; color: var(--sm-text-muted); }
        /* Schedule */
        .gd-schedule-row {
            display: flex; justify-content: space-between; align-items: flex-start;
            padding: 0.5rem 0; border-bottom: 1px solid var(--sm-border); font-size: 0.85rem;
        }
        .gd-schedule-row:last-child { border-bottom: none; }
        .gd-day { font-weight: 600; color: var(--sm-text); min-width: 90px; }
        .gd-time { color: var(--sm-text-muted); }
        /* Messages */
        .gd-message {
            border: 1px solid var(--sm-border); border-radius: var(--sm-radius-md);
            margin-bottom: 1rem; overflow: hidden;
        }
        .gd-message-header {
            display: flex; align-items: baseline; gap: 0.5rem;
            background: #f9fafb; padding: 0.6rem 0.9rem;
            border-bottom: 1px solid var(--sm-border);
        }
        .gd-message-author { font-weight: 600; font-size: 0.88rem; }
        .gd-message-time   { font-size: 0.75rem; color: var(--sm-text-muted); }
        .gd-message-body   { padding: 0.7rem 0.9rem; font-size: 0.9rem; line-height: 1.6; white-space: pre-wrap; }
        /* Replies */
        .gd-replies { border-top: 1px dashed var(--sm-border); background: #fafbff; }
        .gd-reply {
            padding: 0.5rem 0.9rem 0.5rem 1.3rem;
            border-bottom: 1px dashed var(--sm-border); font-size: 0.85rem;
        }
        .gd-reply:last-child { border-bottom: none; }
        .gd-reply-author { font-weight: 600; }
        .gd-reply-time   { font-size: 0.72rem; color: var(--sm-text-muted); margin-left: 0.3rem; }
        .gd-reply-text   { color: var(--sm-text); margin-top: 0.15rem; line-height: 1.5; white-space: pre-wrap; }
        /* Reply form toggle */
        .gd-reply-form { padding: 0.5rem 0.9rem 0.6rem 1.3rem; display: none; }
        .gd-reply-form.open { display: block; }
        .gd-reply-input {
            width: 100%; resize: vertical; min-height: 52px;
            border: 1px solid var(--sm-border); border-radius: 8px;
            padding: 0.4rem 0.6rem; font-size: 0.85rem; font-family: inherit;
            background: #fff;
        }
        .gd-reply-input:focus { outline: none; border-color: var(--sm-primary); }
        /* Post message form */
        .gd-post-form textarea {
            width: 100%; resize: vertical; min-height: 80px;
            border: 1px solid var(--sm-border); border-radius: var(--sm-radius-md);
            padding: 0.55rem 0.75rem; font-size: 0.9rem; font-family: inherit;
            background: #f9fafb; transition: border-color 0.15s, background 0.15s;
            box-sizing: border-box;
        }
        .gd-post-form textarea:focus {
            outline: none; border-color: var(--sm-primary); background: #fff;
        }
        /* Capacity bar */
        .gd-cap-bar { height: 6px; border-radius: 99px; background: #e5e7eb; overflow: hidden; margin-top: 0.35rem; }
        .gd-cap-fill { height: 100%; border-radius: 99px; background: var(--sm-primary); transition: width 0.3s; }
        @media (max-width: 720px) {
            .gd-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>

<header class="sm-header">
    <div class="sm-container sm-header-content">
        <a href="dashboard.jsp" class="sm-logo" style="text-decoration:none;color:inherit;">
            StudyMatch
            <span>course-based study groups</span>
        </a>
        <nav class="sm-nav">
            <span style="color:var(--sm-text-muted);font-size:0.9rem;padding:0.35rem 0.7rem;"><%= userName %></span>
            <a href="searchGroups.jsp" class="sm-btn sm-btn-outline">← Search</a>
            <a href="logout.jsp" class="sm-btn sm-btn-outline">Log out</a>
        </nav>
    </div>
</header>

<main>
  <div class="sm-container">

    <% if (loadError != null) { %>
        <div style="margin-top:2rem;padding:1rem;background:#fee2e2;color:#991b1b;border-radius:10px;">
            Error loading group: <%= loadError %>
        </div>
    <% } else { %>

    <!-- ── Breadcrumb ──────────────────────────────────────────────── -->
    <div style="margin-top:1.25rem;font-size:0.82rem;color:var(--sm-text-muted);">
        <a href="dashboard.jsp" style="color:var(--sm-text-muted);text-decoration:none;">Dashboard</a>
        &rsaquo;
        <a href="searchGroups.jsp" style="color:var(--sm-text-muted);text-decoration:none;">Search</a>
        &rsaquo;
        <span style="color:var(--sm-text);font-weight:500;"><%= groupName %></span>
    </div>

    <!-- ── Two-column grid ────────────────────────────────────────── -->
    <div class="gd-grid">

      <!-- ═══ LEFT COLUMN ═══════════════════════════════════════════ -->
      <div style="display:flex;flex-direction:column;gap:1.25rem;">

        <!-- Group Info Card -->
        <div class="gd-card">
            <div class="gd-section-title">Study Group</div>
            <h1 style="margin:0 0 0.2rem;font-size:1.45rem;"><%= groupName %></h1>
            <div style="font-size:0.9rem;color:var(--sm-text-muted);margin-bottom:0.1rem;">
                <strong style="color:var(--sm-text);"><%= courseId %></strong>
                — <%= deptName %> &middot; <%= courseTitle %>
            </div>
            <div style="font-size:0.85rem;color:var(--sm-text-muted);margin-bottom:0.6rem;">
                Led by <strong style="color:var(--sm-text);"><%= leaderName %></strong>
            </div>

            <!-- Meta pills -->
            <div class="gd-meta">
                <%
                    String modalityClass = "Online".equals(modality) ? "gd-pill-blue"
                                        : "In-Person".equals(modality) ? "gd-pill-green" : "gd-pill-amber";
                    String statusClass   = "Active".equals(status) ? "gd-pill-green"
                                        : "Closed".equals(status)  ? "gd-pill-red"  : "gd-pill-gray";
                %>
                <span class="gd-pill <%= modalityClass %>"><%= modality %></span>
                <span class="gd-pill <%= statusClass %>"><%= status %></span>
                <% if (!location.isEmpty()) { %>
                    <span class="gd-pill gd-pill-gray">📍 <%= location %></span>
                <% } %>
                <% for (String tag : tags) { %>
                    <span class="gd-pill gd-pill-purple"><%= tag %></span>
                <% } %>
            </div>

            <!-- Capacity bar -->
            <div style="margin-top:1rem;">
                <div style="display:flex;justify-content:space-between;font-size:0.8rem;color:var(--sm-text-muted);">
                    <span><%= memberCount %> / <%= maxCapacity %> members</span>
                    <span><%= spotsLeft > 0 ? spotsLeft + " spot" + (spotsLeft == 1 ? "" : "s") + " left" : "Full" %></span>
                </div>
                <div class="gd-cap-bar">
                    <div class="gd-cap-fill" style="width:<%= maxCapacity > 0 ? (memberCount * 100 / maxCapacity) : 0 %>%;"></div>
                </div>
            </div>

            <% if (!description.isEmpty()) { %>
                <p style="margin:1rem 0 0;font-size:0.9rem;color:var(--sm-text-muted);line-height:1.6;">
                    <%= description %>
                </p>
            <% } %>

            <!-- Join button for non-members -->
            <% if (!isMember && currentUserId != leaderId) { %>
                <div style="margin-top:1.1rem;">
                    <% if (spotsLeft > 0 && "Active".equals(status)) { %>
                        <a href="joinGroup.jsp?groupId=<%= groupId %>"
                           class="sm-btn sm-btn-primary">Join this group</a>
                    <% } else if (spotsLeft <= 0) { %>
                        <span style="font-size:0.85rem;color:#6b7280;">This group is full.</span>
                    <% } else { %>
                        <span style="font-size:0.85rem;color:#6b7280;">This group is not accepting members.</span>
                    <% } %>
                </div>
            <% } else if (isMember && currentUserId != leaderId) { %>
                <div style="margin-top:1.1rem;display:flex;align-items:center;gap:0.75rem;">
                    <span class="gd-pill gd-pill-green">✓ You're a member</span>
                    <a href="leaveGroup.jsp?groupId=<%= groupId %>"
                       class="sm-btn sm-btn-outline"
                       style="font-size:0.8rem;padding:0.2rem 0.65rem;color:#dc2626;border-color:#dc2626;"
                       onclick="return confirm('Leave this group?')">Leave group</a>
                </div>
            <% } else { %>
                <div style="margin-top:1.1rem;">
                    <span class="gd-pill gd-pill-purple">You are the leader</span>
                </div>
            <% } %>
        </div>

        <!-- ── Message Board ───────────────────────────────────────── -->
        <div class="gd-card">
            <div class="gd-section-title">Discussion Board</div>

            <% if (justPosted) { %>
                <div style="background:#f0fdf4;color:#15803d;border:1px solid #bbf7d0;
                            border-radius:8px;padding:0.5rem 0.8rem;font-size:0.85rem;margin-bottom:0.9rem;">
                    Posted successfully.
                </div>
            <% } %>

            <!-- Messages list -->
            <% if (messages.isEmpty()) { %>
                <p style="color:var(--sm-text-muted);font-size:0.9rem;margin:0 0 1rem;">
                    No messages yet. Be the first to start the conversation!
                </p>
            <% } else {
                for (String[] msg : messages) {
                    int mid = Integer.parseInt(msg[0]);
                    java.util.List<String[]> msgReplies = replies.getOrDefault(mid, new java.util.ArrayList<>());
            %>
                <div class="gd-message">
                    <div class="gd-message-header">
                        <div class="gd-avatar"><%= msg[1].substring(0,1).toUpperCase() %></div>
                        <span class="gd-message-author"><%= msg[1] %></span>
                        <span class="gd-message-time"><%= msg[3] %></span>
                    </div>
                    <div class="gd-message-body"><%= msg[2] %></div>

                    <!-- Replies -->
                    <% if (!msgReplies.isEmpty()) { %>
                        <div class="gd-replies">
                            <% for (String[] r : msgReplies) { %>
                                <div class="gd-reply">
                                    <div>
                                        <span class="gd-reply-author"><%= r[0] %></span>
                                        <span class="gd-reply-time"><%= r[2] %></span>
                                    </div>
                                    <div class="gd-reply-text"><%= r[1] %></div>
                                </div>
                            <% } %>
                        </div>
                    <% } %>

                    <!-- Reply form (members only) -->
                    <% if (canPost) { %>
                        <div style="padding:0.35rem 0.9rem;border-top:1px solid var(--sm-border);background:#f9fafb;">
                            <button type="button"
                                    onclick="toggleReply(<%= mid %>)"
                                    style="background:none;border:none;cursor:pointer;
                                           font-size:0.8rem;color:var(--sm-primary);padding:0;font-weight:500;">
                                ↩ Reply
                            </button>
                        </div>
                        <div id="replyForm<%= mid %>" class="gd-reply-form">
                            <form method="post" action="groupDetail.jsp?groupId=<%= groupId %>">
                                <input type="hidden" name="action" value="postReply">
                                <input type="hidden" name="messageId" value="<%= mid %>">
                                <textarea name="replyText" class="gd-reply-input"
                                          placeholder="Write a reply…" rows="2" required></textarea>
                                <div style="margin-top:0.35rem;display:flex;gap:0.5rem;">
                                    <button type="submit" class="sm-btn sm-btn-primary"
                                            style="font-size:0.8rem;padding:0.3rem 0.8rem;">Post reply</button>
                                    <button type="button"
                                            onclick="toggleReply(<%= mid %>)"
                                            class="sm-btn sm-btn-outline"
                                            style="font-size:0.8rem;padding:0.3rem 0.8rem;">Cancel</button>
                                </div>
                            </form>
                        </div>
                    <% } %>
                </div>
            <%  }
            } %>

            <!-- Post new message -->
            <% if (canPost) { %>
                <div style="margin-top:0.5rem;padding-top:1rem;border-top:1px solid var(--sm-border);">
                    <div class="gd-section-title" style="margin-bottom:0.5rem;">Post a message</div>
                    <form method="post" action="groupDetail.jsp?groupId=<%= groupId %>" class="gd-post-form">
                        <input type="hidden" name="action" value="postMessage">
                        <textarea name="messageText" placeholder="Write a message to the group…"
                                  required rows="3"></textarea>
                        <div style="margin-top:0.5rem;">
                            <button type="submit" class="sm-btn sm-btn-primary">Post message</button>
                        </div>
                    </form>
                </div>
            <% } else { %>
                <p style="font-size:0.85rem;color:var(--sm-text-muted);margin:0.5rem 0 0;">
                    Join this group to participate in the discussion.
                </p>
            <% } %>
        </div>

      </div><!-- end left column -->

      <!-- ═══ RIGHT COLUMN ══════════════════════════════════════════ -->
      <div style="display:flex;flex-direction:column;gap:1.25rem;">

        <!-- Members Card -->
        <div class="gd-card">
            <div class="gd-section-title">Members
                <span style="font-weight:400;text-transform:none;letter-spacing:0;margin-left:0.3rem;">
                    (<%= memberCount %>/<%= maxCapacity %>)
                </span>
            </div>
            <% if (members.isEmpty()) { %>
                <p style="font-size:0.85rem;color:var(--sm-text-muted);margin:0;">No members yet.</p>
            <% } else {
                for (String[] m : members) {
                    String roleClass = "Leader".equals(m[2]) ? "gd-pill-purple"
                                     : "Co-Leader".equals(m[2]) ? "gd-pill-blue" : "gd-pill-gray";
            %>
                <div class="gd-member">
                    <div class="gd-avatar"><%= m[0].substring(0,1).toUpperCase() %></div>
                    <div class="gd-member-info">
                        <div class="gd-member-name"><%= m[0] %></div>
                        <div class="gd-member-sub"><%= m[1].isEmpty() ? "" : m[1] + " &middot; " %>Joined <%= m[3] %></div>
                    </div>
                    <span class="gd-pill <%= roleClass %>" style="font-size:0.7rem;padding:0.15rem 0.55rem;">
                        <%= m[2] %>
                    </span>
                </div>
            <%  }
            } %>
        </div>

        <!-- Meeting Schedule Card -->
        <div class="gd-card">
            <div class="gd-section-title">Meeting Schedule</div>
            <% if (schedules.isEmpty()) { %>
                <p style="font-size:0.85rem;color:var(--sm-text-muted);margin:0;">No scheduled meetings yet.</p>
            <% } else {
                for (String[] sch : schedules) {
            %>
                <div class="gd-schedule-row">
                    <div>
                        <div class="gd-day"><%= sch[0] %></div>
                        <div class="gd-time"><%= sch[1] %> – <%= sch[2] %></div>
                    </div>
                    <div style="text-align:right;">
                        <% if (!sch[3].isEmpty()) { %>
                            <div style="font-size:0.8rem;color:var(--sm-text-muted);">📍 <%= sch[3] %></div>
                        <% } %>
                        <% if (!sch[4].isEmpty()) { %>
                            <span class="gd-pill gd-pill-blue" style="font-size:0.7rem;margin-top:0.2rem;"><%= sch[4] %></span>
                        <% } %>
                    </div>
                </div>
            <%  }
            } %>
        </div>

        <!-- Quick info card -->
        <div class="gd-card" style="font-size:0.85rem;color:var(--sm-text-muted);">
            <div class="gd-section-title">About</div>
            <div style="display:flex;flex-direction:column;gap:0.45rem;">
                <div><span style="color:var(--sm-text);font-weight:500;">Course</span><br><%= courseId %> – <%= courseTitle %></div>
                <div><span style="color:var(--sm-text);font-weight:500;">Modality</span><br><%= modality %></div>
                <% if (!location.isEmpty()) { %>
                    <div><span style="color:var(--sm-text);font-weight:500;">Location</span><br><%= location %></div>
                <% } %>
                <div><span style="color:var(--sm-text);font-weight:500;">Status</span><br><%= status %></div>
                <div><span style="color:var(--sm-text);font-weight:500;">Capacity</span><br><%= memberCount %> of <%= maxCapacity %> filled</div>
            </div>
        </div>

      </div><!-- end right column -->
    </div><!-- end gd-grid -->

    <% } %>

  </div><!-- sm-container -->
</main>

<footer class="sm-footer">
    <div class="sm-container sm-footer-content">
        <span>© <%= java.time.Year.now() %> StudyMatch</span>
        <span>Built for collaborative learning in higher education.</span>
    </div>
</footer>

<script>
    function toggleReply(messageId) {
        const form = document.getElementById("replyForm" + messageId);
        form.classList.toggle("open");
        if (form.classList.contains("open")) {
            form.querySelector("textarea").focus();
        }
    }
</script>

</body>
</html>
