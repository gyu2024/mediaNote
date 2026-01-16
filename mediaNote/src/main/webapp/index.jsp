<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediaNote - 검색</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <style>
        .container { padding: 20px; max-width: 600px; margin: 0 auto; }
        .logo { font-size: 24px; font-weight: bold; margin-bottom: 20px; color: #333; }
        .input-row { margin-bottom: 15px; }
        .book-extra { display: none; background: #f9f9f9; padding: 15px; border-radius: 5px; margin-bottom: 15px; }
        .radio-group { margin-top: 5px; }
        .btn-submit { padding: 10px 20px; background-color: #007bff; color: white; border: none; cursor: pointer; }
    </style>
</head>
<body>

<div class="container">
    <div class="logo">MediaNote</div>
    
    <form id="searchForm" class="search-form">
        <div class="input-row">
            <select name="mediaType" id="mediaType">
                <option value="" selected disabled>선택</option>
                <option value="book">책</option>
                <option value="drama">드라마</option>
                <option value="movie">영화</option>
            </select>
            <input type="text" name="query" id="query" placeholder="검색어 입력" required autocomplete="off">
        </div>

        <div id="bookOptions" class="book-extra">
            <div class="option-section">
                <div class="option-title"><strong>검색 기준</strong></div>
                <div class="radio-group">
                    <label><input type="radio" name="target" value="title" checked>제목</label>
                    <label><input type="radio" name="target" value="author">저자</label>
                </div>
            </div>
            <br>
            <div class="option-section">
                <div class="option-title"><strong>도서 구분</strong></div>
                <div class="radio-group">
                    <label><input type="radio" name="region" value="domestic" checked>국내</label>
                    <label><input type="radio" name="region" value="foreign">국외</label>
                </div>
            </div>
        </div>

        <button type="submit" class="btn-submit">검색</button>
    </form>
    
    <hr>
    <div id="resultArea">
        </div>
</div>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
$(document).ready(function() {
    // 1. JSP의 내장 객체를 이용하여 Context Path를 자바스크립트 변수로 저장합니다.
    const contextPath = "${pageContext.request.contextPath}";
    
    const $mediaType = $('#mediaType');
    const $bookOptions = $('#bookOptions');
    const $searchForm = $('#searchForm');

    $mediaType.on('change', function() {
        if ($(this).val() === 'book') { $bookOptions.show(); } 
        else { $bookOptions.hide(); }
    });

    $searchForm.on('submit', function(e) {
        e.preventDefault();
        const formData = $(this).serialize();

        $.ajax({
            // 2. url 앞에 contextPath 변수를 붙여서 절대 경로로 요청합니다.
            url: contextPath + "/hello",
            type: "GET",
            data: formData,
            success: function(response) {
                console.log("서버 응답:", response);
                alert("검색 성공! 서버 메시지: " + response);
                $('#resultArea').html("<p style='color:blue;'>결과: " + response + "</p>");
            },
            error: function(xhr, status, error) {
                console.error("에러 발생:", error);
                alert("404 에러 발생: 경로를 확인하세요. 현재 시도 주소: " + contextPath + "/hello");
            }
        });
    });
});
</script>

</body>
</html>