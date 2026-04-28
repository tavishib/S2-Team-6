<%@ page contentType="text/html; charset=UTF-8" %>
<%
    HttpSession s = request.getSession(false);
    if (s != null) s.invalidate();

    String timeout = request.getParameter("timeout");
    if ("true".equals(timeout)) {
        response.sendRedirect("login.jsp?timeout=true");
    } else {
        response.sendRedirect("login.jsp");
    }
%>
