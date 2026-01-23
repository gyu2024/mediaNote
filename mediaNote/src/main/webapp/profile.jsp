<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>내 정보 - MediaNote</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile-extras.css">
</head>
<body>
<%@ include file="/WEB-INF/jsp/partials/header.jsp" %>

<% 
   com.mn.cm.model.User sessionUser = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
   if (sessionUser == null) {
       // try common fallbacks
       Object su = request.getAttribute("USER_SESSION");
       if (su == null) su = session.getAttribute("sessionUser");
       if (su == null) su = request.getAttribute("sessionUser");
       if (su == null) su = session.getAttribute("USER");
       if (su == null) su = request.getAttribute("USER");
       if (su instanceof com.mn.cm.model.User) sessionUser = (com.mn.cm.model.User) su;
   }
   com.mn.cm.model.UserMaster userMaster = (com.mn.cm.model.UserMaster) request.getAttribute("userMaster");
%>

<main class="profile-main<%= (sessionUser == null ? " profile-empty" : "") %>">
    <% if (sessionUser == null) { %>
        <p>로그인이 필요합니다.<br><a href="<%= request.getContextPath() %>/login/kakao?returnUrl=<%= java.net.URLEncoder.encode(request.getRequestURI(), "UTF-8") %>">로그인</a></p>
    <% } else { %>

    <div id="myLnk" class="mypageLnkBox">
           <h2>내 정보</h2>
        <div class="servLnk">
            <ul>
                <li><a href="${pageContext.request.contextPath}/readList" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path transform="translate(10.001 8)" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h16.385v20H0z"></path>
  <path data-name="path 1" d="M203.8 889.028c0-1.04.793-1.276 2.037-1.276 1.211 0 2.036.236 2.036 1.276s-.826 1.276-2.036 1.276c-1.244 0-2.037-.236-2.037-1.276" transform="translate(-191.445 -871.027)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 2" d="M203.8 879.93c0-1.041.793-1.276 2.037-1.276 1.211 0 2.036.235 2.036 1.276s-.826 1.276-2.036 1.276c-1.244 0-2.037-.235-2.037-1.276" transform="translate(-191.445 -866.984)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 3" d="M203.8 898.127c0-1.04.793-1.276 2.037-1.276 1.211 0 2.036.236 2.036 1.276s-.826 1.276-2.036 1.276c-1.244 0-2.037-.236-2.037-1.276" transform="translate(-191.445 -875.071)" class="ico_aFill" fill="#fff"></path>
  <path data-name="line 1" transform="translate(18.817 12.946)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
  <path data-name="line 2" transform="translate(18.817 18.126)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
  <path data-name="line 3" transform="translate(18.817 23.306)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
</svg></em><em class="txt">읽은 책</em></a></li>
                <li><a href="https://ssl.yes24.com/MMyPageOrderClaimList/MMyPageOrderClaimList" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M204.7 1113.028h8.79a2.854 2.854 0 0 0 0-5.708h-8.79l2.212-2.211" transform="translate(-192.951 -1088.652)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 2" d="M198.027 1098.62v12.626h18.824v-14.653h-18.824l2.9-4.344h12.088" transform="translate(-190.028 -1083.018)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 3" d="M227.305 1093.432c-.761-.761-.353-1.514.557-2.424.886-.886 1.662-1.318 2.424-.557s.329 1.538-.557 2.424c-.91.91-1.663 1.318-2.424.557" transform="translate(-202.68 -1082.058)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">반품/교환</em></a></li>
                <li><a href="https://ssl.yes24.com/MMyPageOrderCancelList/MMyPageOrderCancelList" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M197.868 454.527c0-1.041.792-1.276 2.037-1.276 1.21 0 2.036.235 2.036 1.276s-.826 1.276-2.036 1.276c-1.244 0-2.037-.235-2.037-1.276" transform="translate(-185.519 -435.78)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 2" d="M197.868 462.638c0-1.041.792-1.276 2.037-1.276 1.21 0 2.036.235 2.036 1.276s-.826 1.276-2.036 1.276c-1.244 0-2.037-.235-2.037-1.276" transform="translate(-185.519 -439.385)" class="ico_aFill" fill="#fff"></path>
  <path data-name="line 1" transform="translate(12.462 11.094)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M4.409 0 0 4.409"></path>
  <path data-name="line 2" transform="translate(12.462 11.094)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M4.409 4.409 0 0"></path>
  <path transform="translate(9.999 8)" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h16.385v20H0z"></path>
  <path data-name="line 3" transform="translate(18.815 13.143)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
  <path data-name="line 4" transform="translate(18.815 18.323)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
  <path data-name="line 5" transform="translate(18.815 23.503)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" d="M0 0h5.111"></path>
</svg></em><em class="txt">취소내역</em></a></li>
                <li><a href="/MyPage/Account" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path class="ico_line" data-name="패스 1549" d="M27.1 14.9v-2.77a1.711 1.711 0 0 0-1.706-1.706H9.355a1.707 1.707 0 0 0-1.707 1.706v11.739a1.706 1.706 0 0 0 1.707 1.706h16.038a1.706 1.706 0 0 0 1.707-1.706v-2.886" stroke="#ffffff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" transform="translate(.352 -.424)"></path>
  <path class="ico_aFill" data-name="패스 1550" d="M22.045 18c0-1.611 1.227-1.975 3.153-1.975 1.875 0 3.154.364 3.154 1.975s-1.279 1.975-3.154 1.975c-1.926 0-3.153-.364-3.153-1.975" fill="#fff" transform="translate(.352 -.424)"></path>
</svg></em><em class="txt">나의계좌</em></a></li>
                <li><a href="/MyPage/MyAdviceList" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M202.164 604.574v-2.942h15.4v7.268l1.955 4.975-4.713-1.866h-2.988" transform="translate(-189.182 -592.632)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 2" d="m192.221 619.564-1.484 4.749 5.9-4.749h7.668v-9.595h-14.647v9.595h2.56z" transform="translate(-183.659 -596.313)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 3" d="M195.277 618.937c-.83 0-1.018-.633-1.018-1.625 0-.966.188-1.625 1.018-1.625s1.018.659 1.018 1.625c0 .992-.188 1.625-1.018 1.625" transform="translate(-185.691 -598.84)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 4" d="M201.557 618.937c-.831 0-1.018-.633-1.018-1.625 0-.966.187-1.625 1.018-1.625s1.018.659 1.018 1.625c0 .992-.188 1.625-1.018 1.625" transform="translate(-188.465 -598.84)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 5" d="M207.836 618.937c-.831 0-1.018-.633-1.018-1.625 0-.966.188-1.625 1.018-1.625s1.017.659 1.017 1.625c0 .992-.188 1.625-1.017 1.625" transform="translate(-191.238 -598.84)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">1:1문의</em></a></li>
                <li><a href="https://m.yes24.com/Member/CheckMember?action=FTMemUpt" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path transform="translate(4 8)" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-width:1.5px" d="M0 0h28.275v20H0z"></path>
  <path data-name="line 1" transform="translate(19.738 13.493)" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.5px" d="M0 0h8.749"></path>
  <path data-name="line 2" transform="translate(21.405 18.001)" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.5px" d="M0 0h7.082"></path>
  <path data-name="line 3" transform="translate(23.071 22.508)" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.5px" d="M0 0h5.416"></path>
  <path data-name="path 1" d="M204.688 728.082a5.309 5.309 0 0 1 5.151 5.421" transform="translate(-192.133 -708.992)" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-width:1.5px"></path>
  <path data-name="path 2" d="M203.518 728.082a5.078 5.078 0 0 0-4.282 2.421" transform="translate(-190.963 -708.992)" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-width:1.5px"></path>
  <path data-name="path 3" d="M204.079 723.315c-1.254 0-1.538-.955-1.538-2.454 0-1.461.284-2.455 1.538-2.455s1.538.994 1.538 2.455c0 1.5-.284 2.454-1.538 2.454" transform="translate(-191.672 -706.915)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">회원정보</em></a></li>
                <li><a href="https://m.yes24.com/Member/CheckMember?action=MyAddress" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <g id="ico_address" transform="translate(0.029)">
    <rect id="area" width="36" height="36" transform="translate(-0.029)" fill="rgba(255,102,102,0.2)" opacity="0"></rect>
    <g id="path" transform="translate(-5.022)">
      <path id="path1" d="M14.466,11V9.643A1.63,1.63,0,0,1,16.082,8h14.3a1.63,1.63,0,0,1,1.615,1.643h0V26.356A1.63,1.63,0,0,1,30.378,28h-14.3a1.63,1.63,0,0,1-1.616-1.644V25" fill="none" class="ico_line" stroke="#fff" stroke-width="1.5"></path>
      <path id="path2" d="M14.466,19.1v-4" transform="translate(0 0.902)" fill="none" class="ico_line" stroke="#fff" stroke-width="1.5"></path>
      <path id="path3" d="M15.976,23.373c0,1.035-.774,1.27-1.991,1.27-1.185,0-1.992-.235-1.992-1.27s.807-1.267,1.992-1.267c1.217,0,1.991.233,1.991,1.267" transform="translate(0 -1.106)" class="ico_fill" fill="#fff"></path>
      <path id="path4" d="M15.976,12.854c0,1.035-.774,1.268-1.991,1.268-1.185,0-1.992-.233-1.992-1.268s.807-1.268,1.992-1.268c1.217,0,1.991.234,1.991,1.268" transform="translate(0 0.414)" class="ico_fill" fill="#fff"></path>
      <path id="path5" d="M212.933,1215.712a5.535,5.535,0,0,1,5.37,5.654" transform="translate(-189.476 -1196.733)" fill="none" class="ico_line" stroke="#fff" stroke-linejoin="round" stroke-width="1.5"></path>
      <path id="path6" d="M211.457,1215.712a5.293,5.293,0,0,0-4.464,2.525" transform="translate(-188 -1196.733)" fill="none" class="ico_line" stroke="#fff" stroke-linejoin="round" stroke-width="1.5"></path>
      <path id="path_4" data-name="path 4" d="M212.2,1210.288c-1.308,0-1.6-.995-1.6-2.558,0-1.523.3-2.561,1.6-2.561s1.6,1.038,1.6,2.561c0,1.563-.3,2.558-1.6,2.558" transform="translate(-188.895 -1194.114)" class="ico_aFill" fill="#fff"></path>
    </g>
  </g>
</svg></em><em class="txt">나의주소록</em></a></li>
                    <li><a href="https://story24.yes24.com/locker" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 2" d="M21.764 16.066v6.2l-5.551-3.1z" transform="translate(-4.662 -3.964)" style="fill:#ebebeb"></path>
  <path data-name="path 3" d="M8.219 25v6.2l5.551-3.1z" transform="translate(-2.219 -6.694)" style="fill:#ebebeb"></path>
  <path data-name="path 8" d="M26.793 16.066v6.2l5.551-3.1z" transform="translate(-7.895 -3.964)" style="fill:#ebebeb"></path>
  <path data-name="path 9" d="M34.787 20.533v6.2l5.551-3.1z" transform="translate(-10.338 -5.329)" style="fill:#ebebeb"></path>
  <path data-name="path 12" d="m19.321 14.7-5.551-3.1-5.551 3.1 5.551 3.1-5.551 3.1v6.2l5.551 3.1 5.551-3.1L13.77 24l5.551-3.1z" style="fill:none;stroke:#4d5156;stroke-linecap:round;stroke-linejoin:round;stroke-width:1.5px" transform="translate(-2.219 -2.599)"></path>
  <path data-name="path 12" d="M32.344 17.8v-6.2l-5.551 3.1v6.2l5.551 3.1v6.2l5.551-3.1V14.7z" transform="translate(-7.895 -2.599)" style="fill:none;stroke:#4d5156;stroke-linecap:round;stroke-linejoin:round;stroke-width:1.5px"></path>
</svg></em><em class="txt">나의웹소설</em></a></li>
                                <li><a href="/YesFunding/MyFunding?type=ORDER" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="m5.5 15.258 12.887-7.413 11.231 6.461a1.76 1.76 0 0 1-1.736 3.061l-9.5-5.3-9.2 5.21V29.1h18.123v-8.889" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" transform="translate(.499 .098)"></path>
  <path data-name="path 2" d="M27.2 10.786c-.992 0-1.217-.756-1.217-1.942C25.98 7.689 26.2 6.9 27.2 6.9s1.217.787 1.217 1.942c0 1.186-.224 1.942-1.217 1.942" class="ico_aFill" fill="#fff" transform="translate(.499 .098)"></path>
  <path data-name="path 3" d="M18.443 20.525c.632-1 1.689-1.983 4.126-2.029h.25v5.133s-3.332-.464-4.091 2.483a.143.143 0 0 1-.269 0c-.761-2.947-4.092-2.483-4.092-2.483V18.5c2.437.046 3.494 1.032 4.126 2.029v2.228" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px" transform="translate(.499 .098)"></path>
</svg></em><em class="txt">나의펀딩</em></a></li>
                <li><a href="https://ssl.yes24.com/mMyPage/MyPageClass24List" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <g id="ico_class24" transform="translate(0.029)">
    <rect id="area" width="36" height="36" transform="translate(-0.029)" fill="rgba(255,102,102,0.2)" opacity="0"></rect>
    <g id="path" transform="translate(-5.522 2.236)">
      <path id="path1" d="M14.466,11V9.643A1.5,1.5,0,0,1,15.757,8H27.176a1.5,1.5,0,0,1,1.29,1.643h0V26.356A1.5,1.5,0,0,1,27.176,28H15.757a1.5,1.5,0,0,1-1.291-1.644V25" transform="translate(5.493 35.229) rotate(-90)" fill="none" class="ico_line" stroke="#fff" stroke-width="1.5"></path>
      <g id="그룹_333" data-name="그룹 333" transform="translate(-0.201)">
        <path id="path5" d="M212.933,1215.712a5.317,5.317,0,0,1,5.555,5" transform="translate(-189.294 -1196.733)" fill="none" class="ico_line" stroke="#fff" stroke-linejoin="round" stroke-width="1.5"></path>
        <path id="path5-2" data-name="path5" d="M218.488,1215.712a5.317,5.317,0,0,0-5.555,5" transform="translate(-194.739 -1196.733)" fill="none" class="ico_line" stroke="#fff" stroke-linejoin="round" stroke-width="1.5"></path>
      </g>
      <path id="path_4" data-name="path 4" d="M212.094,1210.169c-1.224,0-1.5-.972-1.5-2.5,0-1.487.276-2.5,1.5-2.5s1.5,1.014,1.5,2.5c0,1.527-.276,2.5-1.5,2.5" transform="translate(-188.601 -1194.114)" class="ico_aFill" fill="#fff"></path>
    </g>
  </g>
</svg></em><em class="txt">클래스24</em></a></li>
                <li><a href="https://m.yes24.com/MyPage/Addon" class="lnk"><em class="ico"><svg id="icon__adON" data-name="icon_ adON" xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <rect id="area" width="36" height="36" fill="rgba(255,0,0,0.2)" opacity="0"></rect>
  <g id="path" transform="translate(-20.5 -20)">
    <path id="패스_2570" data-name="패스 2570" d="M24,4h.769a3.846,3.846,0,0,1,3.846,3.846V20.154A3.846,3.846,0,0,1,24.769,24H24" transform="translate(25 54) rotate(-90)" fill="none" stroke="#333" stroke-width="1.5"></path>
    <path id="패스_2571" data-name="패스 2571" d="M4,20h.769a3.846,3.846,0,0,0,3.846-3.846V3.846A3.846,3.846,0,0,0,4.769,0H4" transform="translate(49 42) rotate(90)" fill="none" stroke="#333" stroke-width="1.5"></path>
    <path id="패스_2661" data-name="패스 2661" d="M-11.757-8.089c-1.294-.005-2.127,1.348-2.127,3.534S-13.052-1-11.757-1-9.6-2.358-9.6-4.555-10.458-8.094-11.757-8.089Zm-.859,3.534c-.011-1.5.312-2.245.859-2.245.564,0,.9.747.892,2.245s-.328,2.245-.892,2.234C-12.305-2.31-12.627-3.051-12.617-4.555ZM-8.986.537h1.3V-3.942h.881V.988h1.311V-8.787H-6.805V-5.06h-.881V-8.647h-1.3Zm12.493-4.8H-2.057v-2.6H3.432V-7.971H-3.411v4.8H3.507ZM-4.463-.2H4.485V-1.332H-4.463ZM13.959-3.749H10.178v-.779c-.011-.024-1.376,0-1.375-.005v.784H5.043v1.1h8.916ZM6.118.816H12.95v-1.1H7.493V-2.041H6.118Z" transform="translate(38.5 42)" fill="#333"></path>
    <path id="path_9" data-name="path 9" d="M12.606,12.533c0-1.581,1.342-1.939,3.448-1.939,2.051,0,3.448.357,3.448,1.939s-1.4,1.939-3.448,1.939c-2.106 0-3.448-.357-3.448-1.939" transform="translate(31.894 22.406)" fill="#0080ff"></path>
  </g>
</svg></em><em class="txt">애드온 정산관리</em></a></li>
                <li><a href="http://m.ticket.yes24.com/MyPage/Main.aspx" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M32 6.126v16.04l-14-2.347-14 2.346V6.126l14 2.345z" class="ico_line" stroke="#fff" style="stroke-linejoin:round;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 2" d="M11.136 29.875a1.985 1.985 0 0 0-3.971 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 3" d="M16.691 29.875a1.985 1.985 0 0 0-3.971 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 4" d="M22.245 29.875a1.986 1.986 0 0 0-3.971 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 5" d="M27.8 29.875a1.985 1.985 0 0 0-3.971 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 6" d="M13.383 26.583a1.985 1.985 0 1 0-3.97 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 7" d="M18.939 26.583a1.986 1.986 0 0 0-3.972 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 8" d="M24493 26.583a1.986 1.986 0 0 0-3.971 0" class="ico_line" stroke="#fff" style="stroke-miterlimit:10;fill:none;stroke-width:1.52px" transform="translate(0 -.126)"></path>
  <path data-name="path 9" d="M12.606 14.145c0-2.9 2.206-3.551 5.668-3.551 3.372 0 5.669.654 5.669 3.551s-2.3 3.551-5.669 3.551c-3.462 0-5.668-.654-5.668-3.551" class="ico_aFill" fill="#fff" transform="translate(0 -.126)"></path>
</svg></em><em class="txt">나의티켓</em></a></li>
                <li><a href="https://m.yes24.com/GiftOrder/GiftBox" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M232.643 1054.026h-19.877a1.873 1.873 0 0 0-1.873 1.873v.7a1.873 1.873 0 0 0 1.873 1.873H228a1.873 1.873 0 0 1 1.873 1.873v5.28A1.873 1.873 0 0 1 228 1067.5h-12.466a1.873 1.873 0 0 1-1.873-1.873v-4.254" transform="translate(-203.893 -1039.496)" class="ico_line" stroke="#fff" style="fill:none;stroke-miterlimit:10;stroke-width:1.5px"></path>
  <path data-name="path 2" d="M227.549 1037.928c-.914.571-.686 1.4 0 2.489.665 1.064 1.325 1.661 2.239 1.089s.668-1.426 0-2.49c-.683-1.093-1.325-1.66-2.239-1.089" transform="translate(-213.525 -1029.702)" class="ico_aFill" fill="#fff"></path>
  <path data-name="path 2" d="M243.456 1037.928c.914.571.686 1.4 0 2.489-.665 1.064-1.325 1.661-2.239 1.089s-.668-1.426 0-2.49c.683-1.093 1.325-1.66 2.239-1.089" transform="translate(-221.731 -1029.702)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">선물함</em></a></li>
                    <li><a href="https://m.yes24.com/Member/CheckMember?action=Security" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M220.114 1201.645v13.127a16.334 16.334 0 0 1-9.757 9.315l-.243.082-.236-.082a16.363 16.363 0 0 1-9.764-9.315v-13.127c4.923 0 9.029-1.943 10.007-4.533.972 2.588 5.07 4.533 9.993 4.533z" transform="translate(-192.115 -1193.112)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 2" d="M212.933 1215.712a5.535 5.535 0 0 1 5.37 5.654" transform="translate(-195.3 -1197.733)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 3" d="M211.457 1215.712a5.293 5.293 0 0 0-4.464 2.525" transform="translate(-193.824 -1197.733)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 4" d="M212.2 1210.288c-1.308 0-1.6-.995-1.6-2.558 0-1.523.3-2.561 1.6-2.561s1.6 1.038 1.6 2.561c0 1.563-.3 2.558-1.6 2.558" transform="translate(-194.719 -1195.114)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">보안설정</em></a></li>
                <li><a href="/MyPage/MyReviewComment" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="m204.886 1158.03 1.787.259-1.292 1.261.305 1.781-1.6-.84-1.6.841.305-1.781-1.295-1.26 1.788-.261.8-1.619z" transform="translate(-193.572 -1141.003)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 2" d="m215.031 1158.03 1.788.259-1.292 1.261.305 1.781-1.6-.84-1.6.841.305-1.781-1.295-1.26 1.788-.261.8-1.619z" transform="translate(-196.233 -1141.003)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 3" d="m225.177 1158.03 1.787.259-1.292 1.261.305 1.781-1.6-.84-1.6.841.305-1.781-1.295-1.26 1.788-.261.8-1.619z" transform="translate(-198.895 -1141.003)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 4" d="M215.662 1150.1h-20.844v14.564h4.928l-.327 3.817 5.831-3.817h19.568V1150.1h-2.224" transform="translate(-191.819 -1139.347)" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px"></path>
  <path data-name="path 5" d="M227.2 1151.091c-1.554 0-1.9-1.182-1.9-3.038 0-1.807.35-3.039 1.9-3.039s1.9 1.233 1.9 3.039c0 1.857-.35 3.038-1.9 3.038" transform="translate(-199.815 -1138.013)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">나의리뷰</em></a></li>
                <li><a href="https://m.yes24.com/Member/CheckMember?action=PrivacyUseInfo" class="lnk"><em class="ico"><svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
  <path data-name="path 1" d="M219.986 1040.916c.564.055 1.143.082 1.735.082v13.127a16.334 16.334 0 0 1-9.756 9.316l-.244.081-.236-.081a16.365 16.365 0 0 1-9.764-9.316V1041c4.923 0 9.029-1.943 10.008-4.533a5.857 5.857 0 0 0 2.77 2.86" class="ico_line" stroke="#fff" style="fill:none;stroke-linejoin:round;stroke-width:1.5px" transform="translate(-193.721 -1032.465)"></path>
  <path data-name="path 2" d="M208.786 1046.252h-1.673v-.85h2.721a4.791 4.791 0 0 1-2.475 4.621l-.619-.738a3.731 3.731 0 0 0 2.046-3.033m3.977 5.158h-1.021v-3.444h-.529v3.153h-.991v-6.373h.991v2.356h.529v-2.534h1.021z" transform="translate(-194.968 -1034.478)" class="ico_fill" fill="#fff"></path>
  <path data-name="path 3" d="M217.679 1045a1.75 1.75 0 1 1-1.893 1.736 1.78 1.78 0 0 1 1.893-1.736m-.872 3.973h1.093v1.469h3.72v.858h-4.808zm.872-1.417a.813.813 0 1 0-.849-.82.781.781 0 0 0 .849.82m3.765 1.908h-1.073v-4.89h1.073z" transform="translate(-197.215 -1034.48)" class="ico_fill" fill="#fff"></path>
  <path data-name="path 4" d="M208.414 1056.043h-1.309v-.858h3.712v.858h-1.3a2.051 2.051 0 0 0 1.529 1.826l-.522.842a2.551 2.551 0 0 1-1.543-1.289 2.649 2.649 0 0 1-1.626 1.46l-.558-.85a2.192 2.192 0 0 0 1.614-1.989m1.881 2.944c1.48 0 2.382.5 2.385 1.333s-.9 1.332-2.385 1.335c-1.46 0-2.363-.5-2.363-1.335s.9-1.329 2.363-1.333m0 1.849c.873 0 1.312-.16 1.319-.516s-.446-.521-1.319-.521c-.854 0-1.3.161-1.3.521s.443.519 1.3.516m2.364-1.975h-1.066v-1.561h-.97v-.865h.97v-1.635h1.066z" transform="translate(-194.983 -1037.019)" class="ico_fill" fill="#fff"></path>
  <path data-name="path 5" d="M221.921 1061.013h-6.254v-.872h2.587v-1.2h-1.946v-3.578h1.073v1.007h2.8v-1.007h1.074v3.578h-1.938v1.2h2.609zm-1.744-3.8h-2.8v.88h2.8z" transform="translate(-197.186 -1037.16)" class="ico_fill" fill="#fff"></path>
  <path data-name="path 6" d="M221.138 1041.791c-1.008-.478-.87-1.354-.3-2.558.558-1.174 1.164-1.865 2.172-1.387s.856 1.387.3 2.558c-.571 1.205-1.163 1.865-2.171 1.387" transform="translate(-198.36 -1032.77)" class="ico_aFill" fill="#fff"></path>
</svg></em><em class="txt">이용내역</em></a></li>
            </ul>
        </div>
    </div>

    <script>
        (function(){
            var tabs = document.querySelectorAll('.profile-tab-btn');
            var contents = document.querySelectorAll('.tab-content');
            function activate(tabName) {
                tabs.forEach(function(b){
                    if (b.getAttribute('data-tab') === tabName) { b.classList.add('active'); }
                    else { b.classList.remove('active'); }
                });
                contents.forEach(function(c){
                    if (c.getAttribute('data-content') === tabName) { c.classList.remove('tab-content--hidden'); }
                    else { c.classList.add('tab-content--hidden'); }
                });
            }
            // default
            activate('overview');
            tabs.forEach(function(b){ b.addEventListener('click', function(e){ var t = this.getAttribute('data-tab'); if (t) activate(t); }); });
        })();

        // Prevent sticky header overlap on small widths without changing CSS
        (function(){
            function adjustProfileTopPadding(){
                try {
                    var header = document.querySelector('.site-header');
                    var main = document.querySelector('.profile-main');
                    if (!header || !main) return;
                    var h = header.getBoundingClientRect().height || header.offsetHeight || 0;
                    // add a small buffer so content breathes
                    var pad = Math.max(20, Math.ceil(h));
                } catch(e) {}
            }
            // run on load and when viewport changes
            try {
                adjustProfileTopPadding();
                window.addEventListener('resize', function(){ adjustProfileTopPadding(); });
                // if fonts or images load later and header height changes, re-run once after load
                window.addEventListener('load', function(){ setTimeout(adjustProfileTopPadding, 50); });
            } catch(e) {}
        })();
    </script>

    <% } %>
</main>

<footer class="site-footer">
    © MediaNote
</footer>

</body>
</html>
