<%
int userId = Integer.parseInt(request.getParameter("userId"));

Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/StudyMatch","root","CS157A@sjsu");

PreparedStatement ps = conn.prepareStatement(
    "UPDATE User SET is_banned = TRUE WHERE user_id = ?"
);
ps.setInt(1, userId);
ps.executeUpdate();

response.sendRedirect("adminUsers.jsp");
%>