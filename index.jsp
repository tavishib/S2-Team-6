<%@ page contentType="text/html; charset=UTF-8" language="java" %>
<%
    if (session != null && session.getAttribute("userId") != null) {
        response.sendRedirect("dashboard.jsp");
    } else {
        response.sendRedirect("login.jsp");
    }
%>
