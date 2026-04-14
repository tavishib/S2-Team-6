import java.io.IOException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@WebServlet("/deleteAccount")
public class DeleteAccountServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        request.getRequestDispatcher("deleteAccount.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        int userId = (int) session.getAttribute("userId");

        try (Connection conn = DBConnection.getConnection()) {

            // Collect group IDs where this user is the leader
            List<Integer> ledGroups = new ArrayList<>();
            String findGroups = "SELECT group_id FROM Study_Group WHERE leader_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(findGroups)) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    ledGroups.add(rs.getInt("group_id"));
                }
            }

            conn.setAutoCommit(false);
            try {
                // --- Clean up groups this user leads ---
                if (!ledGroups.isEmpty()) {
                    String groupPlaceholders = placeholders(ledGroups.size());

                    // Replies on messages inside those groups
                    String delRepliesInGroups =
                        "DELETE FROM Reply WHERE message_id IN " +
                        "(SELECT message_id FROM Message WHERE group_id IN (" + groupPlaceholders + "))";
                    try (PreparedStatement ps = conn.prepareStatement(delRepliesInGroups)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }

                    // Group tags
                    String delGroupTags = "DELETE FROM Group_Tag WHERE group_id IN (" + groupPlaceholders + ")";
                    try (PreparedStatement ps = conn.prepareStatement(delGroupTags)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }

                    // Meeting schedules
                    String delMeetings = "DELETE FROM Meeting_Schedule WHERE group_id IN (" + groupPlaceholders + ")";
                    try (PreparedStatement ps = conn.prepareStatement(delMeetings)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }

                    // All messages in those groups (authored by anyone)
                    String delMessages = "DELETE FROM Message WHERE group_id IN (" + groupPlaceholders + ")";
                    try (PreparedStatement ps = conn.prepareStatement(delMessages)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }

                    // All memberships in those groups
                    String delMemberships = "DELETE FROM Membership WHERE group_id IN (" + groupPlaceholders + ")";
                    try (PreparedStatement ps = conn.prepareStatement(delMemberships)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }

                    // The groups themselves
                    String delGroups = "DELETE FROM Study_Group WHERE group_id IN (" + groupPlaceholders + ")";
                    try (PreparedStatement ps = conn.prepareStatement(delGroups)) {
                        setInts(ps, ledGroups, 1);
                        ps.executeUpdate();
                    }
                }

                // --- Clean up this user's own remaining data ---

                // Replies authored by this user (in groups they don't lead)
                String delUserReplies = "DELETE FROM Reply WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delUserReplies)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // Messages authored by this user (in groups they don't lead)
                String delUserMessages = "DELETE FROM Message WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delUserMessages)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // Memberships for this user
                String delUserMemberships = "DELETE FROM Membership WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delUserMemberships)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // Student or Administrator subtype row
                String delStudent = "DELETE FROM Student WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delStudent)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }
                String delAdmin = "DELETE FROM Administrator WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delAdmin)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                // User row
                String delUser = "DELETE FROM User WHERE user_id = ?";
                try (PreparedStatement ps = conn.prepareStatement(delUser)) {
                    ps.setInt(1, userId);
                    ps.executeUpdate();
                }

                conn.commit();

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }

        } catch (SQLException e) {
            request.setAttribute("error", "Database error: " + e.getMessage());
            request.getRequestDispatcher("deleteAccount.jsp").forward(request, response);
            return;
        }

        // Invalidate session and redirect to login
        session.invalidate();
        response.sendRedirect("login.jsp?deleted=true");
    }

    private String placeholders(int n) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < n; i++) {
            if (i > 0) sb.append(',');
            sb.append('?');
        }
        return sb.toString();
    }

    private void setInts(PreparedStatement ps, List<Integer> values, int startIndex)
            throws SQLException {
        for (int i = 0; i < values.size(); i++) {
            ps.setInt(startIndex + i, values.get(i));
        }
    }
}
