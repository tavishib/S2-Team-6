import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    // 15 minutes in seconds
    private static final int SESSION_TIMEOUT = 15 * 60;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.isBlank() || password.isBlank()) {
            request.setAttribute("error", "Email and password are required.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        String passwordHash = hashPassword(password);
        if (passwordHash == null) {
            request.setAttribute("error", "Server error, please try again.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            String query = "SELECT u.user_id, u.name, u.email, u.password_hash, " +
                           "s.major, a.admin_level " +
                           "FROM User u " +
                           "LEFT JOIN Student s ON u.user_id = s.user_id " +
                           "LEFT JOIN Administrator a ON u.user_id = a.user_id " +
                           "WHERE u.email = ?";

            try (PreparedStatement ps = conn.prepareStatement(query)) {
                ps.setString(1, email.toLowerCase().trim());
                ResultSet rs = ps.executeQuery();

                if (!rs.next()) {
                    request.setAttribute("error", "Invalid email or password.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                String storedHash = rs.getString("password_hash");
                if (!storedHash.equals(passwordHash)) {
                    request.setAttribute("error", "Invalid email or password.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                // Credentials match — create session
                HttpSession session = request.getSession(true);
                session.setMaxInactiveInterval(SESSION_TIMEOUT);
                session.setAttribute("userId",   rs.getInt("user_id"));
                session.setAttribute("userName", rs.getString("name"));
                session.setAttribute("userEmail", rs.getString("email"));

                // Determine role
                String major      = rs.getString("major");
                int    adminLevel = rs.getInt("admin_level");
                if (major != null) {
                    session.setAttribute("role", "Student");
                    session.setAttribute("major", major);
                } else {
                    session.setAttribute("role", "Admin");
                    session.setAttribute("adminLevel", adminLevel);
                }

                response.sendRedirect("dashboard.jsp");
            }

        } catch (SQLException e) {
            request.setAttribute("error", "Database error: " + e.getMessage());
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }

    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            return null;
        }
    }
}
