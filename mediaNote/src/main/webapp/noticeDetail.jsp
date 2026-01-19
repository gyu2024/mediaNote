<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    Map<String,Object> notice = (Map<String,Object>) request.getAttribute("notice");
    if (notice == null) {
        notice = new HashMap<>();
        notice.put("TITLE", "공지사항을 찾을 수 없습니다.");
        notice.put("CONTENT", "");
    }
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>공지사항 상세</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />
<div class="container detail-view">
    <a href="<%= request.getContextPath() %>/notice/list">← 공지사항 목록으로</a>
    <h1 style="margin-top:12px;"><%= notice.get("TITLE") %></h1>
    <div style="color:#777; font-size:13px; margin-bottom:12px;">작성자: <%= notice.get("WRITER") %> | 등록일: <%= notice.get("REG_DT") %> | 조회: <%= notice.get("VIEW_CNT") %></div>
    <div style="white-space:pre-wrap; line-height:1.6; color:#333;"><%= notice.get("CONTENT") %></div>
</div>
</body>
</html>
