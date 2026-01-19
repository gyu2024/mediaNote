<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    List<Map<String,Object>> notices = (List<Map<String,Object>>) request.getAttribute("notices");
    if (notices == null) notices = new ArrayList<>();
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>공지사항 목록</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />
<div class="container detail-view">
    <h1>공지사항</h1>
    <table style="width:100%; border-collapse:collapse;">
        <thead>
            <tr style="text-align:left; border-bottom:1px solid #eee;">
                <th style="padding:8px; width:80px;">ID</th>
                <th style="padding:8px;">제목</th>
                <th style="padding:8px; width:120px;">작성일</th>
                <th style="padding:8px; width:80px; text-align:right;">조회수</th>
            </tr>
        </thead>
        <tbody>
            <% for (Map<String,Object> n : notices) { %>
            <tr style="border-bottom:1px solid #f6f6f6;">
                <td style="padding:8px; vertical-align:top;"><%= n.get("NOTICE_ID") %></td>
                <td style="padding:8px; vertical-align:top;">
                    <a href="<%= request.getContextPath() %>/notice/view?id=<%= n.get("NOTICE_ID") %>"><%= n.get("TITLE") %></a>
                    <% if ("Y".equals(String.valueOf(n.get("FIX_YN")))) { %>
                        <span style="background:#fffae6; color:#c77d00; padding:2px 6px; border-radius:6px; margin-left:8px; font-size:12px;">고정</span>
                    <% } %>
                </td>
                <td style="padding:8px; vertical-align:top;"><%= n.get("REG_DT") %></td>
                <td style="padding:8px; vertical-align:top; text-align:right;"><%= n.get("VIEW_CNT") %></td>
            </tr>
            <% } %>
        </tbody>
    </table>
</div>
</body>
</html>
