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

@WebServlet("/signup")
public class SignupServlet extends HttpServlet {

    private static final int MIN_PASSWORD_LENGTH = 8;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("signup.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String name     = request.getParameter("name");
        String email    = request.getParameter("email");
        String password = request.getParameter("password");
        String major    = request.getParameter("major");

        // Required field validation
        if (isBlank(name) || isBlank(email) || isBlank(password) || isBlank(major)) {
            forward(request, response, "All fields are required.");
            return;
        }

        // SJSU email validation
        if (!email.toLowerCase().endsWith("@sjsu.edu")) {
            forward(request, response, "Email must be a valid SJSU email address (e.g. yourname@sjsu.edu).");
            return;
        }

        // Password length validation
        if (password.length() < MIN_PASSWORD_LENGTH) {
            forward(request, response, "Password must be at least " + MIN_PASSWORD_LENGTH + " characters.");
            return;
        }

        String passwordHash = hashPassword(password);
        if (passwordHash == null) {
            forward(request, response, "Server error, please try again.");
            return;
        }

        try (Connection conn = DBConnection.getConnection()) {

            // Check if email is already registered
            String checkEmail = "SELECT user_id FROM User WHERE email = ?";
            try (PreparedStatement ps = conn.prepareStatement(checkEmail)) {
                ps.setString(1, email.toLowerCase());
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    forward(request, response, "An account with that email already exists.");
                    return;
                }
            }

            // Insert into User
            String insertUser = "INSERT INTO User (name, email, password_hash) VALUES (?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(insertUser,
                    PreparedStatement.RETURN_GENERATED_KEYS)) {

                ps.setString(1, name.trim());
                ps.setString(2, email.toLowerCase().trim());
                ps.setString(3, passwordHash);
                ps.executeUpdate();

                ResultSet keys = ps.getGeneratedKeys();
                if (!keys.next()) {
                    forward(request, response, "Could not create account. Please try again.");
                    return;
                }
                int userId = keys.getInt(1);

                // Insert into Student
                String insertStudent = "INSERT INTO Student (user_id, major) VALUES (?, ?)";
                try (PreparedStatement ps2 = conn.prepareStatement(insertStudent)) {
                    ps2.setInt(1, userId);
                    ps2.setString(2, major.trim());
                    ps2.executeUpdate();
                }
            }

            // Redirect to login with success message
            response.sendRedirect("login.jsp?registered=true");

        } catch (SQLException e) {
            forward(request, response, "Database error: " + e.getMessage());
        }
    }

    private void forward(HttpServletRequest request, HttpServletResponse response, String error)
            throws ServletException, IOException {
        request.setAttribute("error", error);
        request.getRequestDispatcher("signup.jsp").forward(request, response);
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
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
