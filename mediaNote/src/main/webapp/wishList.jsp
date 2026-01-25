<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="jakarta.servlet.http.HttpServletRequest" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>위시리스트 - MediaNote</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile-extras.css">
</head>
<body>
<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />
<main class="container">
    <h2>위시리스트</h2>
    <% if (request.getAttribute("wishError") != null) { %>
        <div style="color:#b00; background:#fee; padding:10px; border-radius:4px; margin-bottom:8px;">서버 오류: <%= String.valueOf(request.getAttribute("wishError")) %></div>
    <% } %>
    <!-- floating back button (styled like bookDetail.jsp) -->
    <a href="${pageContext.request.contextPath}/profile" id="backToList" class="back-to-list" aria-label="검색으로 돌아가기">← 돌아가기</a>
    <% java.util.List<java.util.Map<String,Object>> serverItems = (java.util.List<java.util.Map<String,Object>>) request.getAttribute("wishItems"); %>
    <div id="readArea" style="margin: 15px 0px 0px 0;">
        <% if (serverItems != null && !serverItems.isEmpty()) { %>
            <table class="result-table">
                <% for (java.util.Map<String,Object> it : serverItems) { %>
                    <tr data-isbn="<%= it.get("isbn") != null ? it.get("isbn") : "" %>" data-isbn13="<%= it.get("isbn13") != null ? it.get("isbn13") : "" %>">
                        <td class="info-cover"><a class="mn-item-link" href="<%= (it.get("isbn")!=null && String.valueOf(it.get("isbn")).length()>0) ? (((HttpServletRequest)request).getContextPath()+"/book/view?isbn="+java.net.URLEncoder.encode(String.valueOf(it.get("isbn")), "UTF-8")) : "#" %>">
                            <img src="<%= it.get("cover") != null ? it.get("cover") : "" %>" alt="<%= it.get("title") != null ? it.get("title") : "" %>" />
                        </a></td>
                        <td class="info-details">
                            <a class="mn-item-link" href="<%= (it.get("isbn")!=null && String.valueOf(it.get("isbn")).length()>0) ? (((HttpServletRequest)request).getContextPath()+"/book/view?isbn="+java.net.URLEncoder.encode(String.valueOf(it.get("isbn")), "UTF-8")) : "#" %>"><div class="info-title"><%= it.get("title") != null ? it.get("title") : "제목 없음" %></div></a>
                            <div class="info-meta"><div class="info-author"><%= it.get("author") != null ? it.get("author") : "" %></div><div class="info-publisher-date"><%= it.get("publisher") != null ? it.get("publisher") : "" %></div></div>
                            <div class="info-actions"><button class="btn btn-rvw" type="button">💬</button><button class="btn btn-read" type="button">📖</button><button class="btn btn-wish active" type="button">💖</button></div>
                        </td>
                    </tr>
                <% } %>
            </table>
        <% } else { %>
            <p style="color:#777;">불러오는 중...</p>
        <% } %>
    </div>
</main>

<!-- review modal (copied minimal modal from index.jsp) -->
<div id="reviewModal" class="mn-modal-overlay" aria-hidden="true" style="display:none;">
    <div class="mn-modal" role="dialog" aria-modal="true" aria-labelledby="mn-modal-title">
        <header class="mn-modal-header">
            <h3 id="mn-modal-title">리뷰 작성</h3>
            <button class="mn-modal-close" aria-label="닫기" onclick="try{ window.closeReviewModal && window.closeReviewModal(); }catch(e){ console.error('inline close error', e); }">✕</button>
        </header>
        <section class="mn-modal-body">
            <div class="mn-row">
                <label class="mn-label">평점</label>
                <div class="mn-rating">
                    <div id="starDisplay" class="star-display" aria-hidden="true">☆☆☆☆☆</div>
                    <select id="rvw_rating" class="mn-select">
                        <option value="">선택</option>
                        <option value="1.0">1.0</option>
                        <option value="1.5">1.5</option>
                        <option value="2.0">2.0</option>
                        <option value="2.5">2.5</option>
                        <option value="3.0">3.0</option>
                        <option value="3.5">3.5</option>
                        <option value="4.0">4.0</option>
                        <option value="4.5">4.5</option>
                        <option value="5.0">5.0</option>
                    </select>
                </div>
            </div>
            <div class="mn-row" style="justify-content: center;">
                <div class="rating-guide-container" style="width: 100%;">
                    <strong class="rating-title">⭐ 평점 가이드</strong>
                    <ul class="rating-list">
                        <li class="rating-item"><span class="rating-score">5.0</span><span class="rating-desc">인생 책 (삶에 영향을 준 최고의 책)</span></li>
                        <li class="rating-item"><span class="rating-score">4.0 ~ 4.5</span><span class="rating-desc">추천 (재미있고 남들에게 권하고 싶은 책)</span></li>
                        <li class="rating-item"><span class="rating-score">3.0 ~ 3.5</span><span class="rating-desc">무난 (읽을만하고 시간이 아깝지 않은 수준)</span></li>
                        <li class="rating-item"><span class="rating-score">2.0 ~ 2.5</span><span class="rating-desc">아쉬움 (기대에 못 미치거나 지루함)</span></li>
                        <li class="rating-item"><span class="rating-score">1.0</span><span class="rating-desc">시간 아까움 (내용이 부실하거나 권하고 싶지 않음)</span></li>
                    </ul>
                </div>
            </div>
            <div class="mn-row">
                <label class="mn-label" for="rvw_comnet">한 줄 평</label>
                <input id="rvw_comnet" placeholder="한 줄 평 (생략 가능)" maxlength="200" class="mn-input">
            </div>
            <div class="mn-row">
                <label class="mn-label" for="rvw_text">감상평</label>
                <textarea id="rvw_text" placeholder="감상평을 입력하세요 (생략 가능)" maxlength="2000" class="mn-textarea"></textarea>
            </div>
        </section>
        <footer class="mn-modal-footer">
            <button id="rvw_cancel" class="mn-btn mn-btn-secondary" type="button">취소</button>
            <button id="rvw_delete" class="mn-btn mn-btn-danger" type="button" style="margin-right:6px; display:none;">삭제</button>
            <button id="rvw_save" class="mn-btn mn-btn-primary" type="button">저장</button>
        </footer>
    </div>
</div>

<footer class="site-footer">© MediaNote</footer>

<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
    (function(){
        var ctx = '${pageContext.request.contextPath}';
        function normalize(resp){
            if (!resp) return [];
            if (Array.isArray(resp)) return resp;
            if (resp.data && Array.isArray(resp.data)) return resp.data;
            if (resp.items && Array.isArray(resp.items)) return resp.items;
            if (resp.list && Array.isArray(resp.list)) return resp.list;
            var out = [];
            Object.keys(resp).forEach(function(k){ if (Array.isArray(resp[k])) out = out.concat(resp[k]); });
            return out;
        }

        // small helpers copied from index.jsp for consistent localStorage keys and auth flow
        function makeStorageKey(prefix, rawKey) {
            try { return prefix + ':' + btoa(unescape(encodeURIComponent(rawKey || ''))); } catch (e) { return prefix + ':' + (rawKey || ''); }
        }

        function requireLoginThen(action, pending) { $.get(ctx + '/auth/check', function(resp){ if (resp === 'OK') { action && action(); } else { try { if (pending) { pending.returnUrl = location.pathname + (location.search || ''); localStorage.setItem('mn_pending_action', JSON.stringify(pending)); } } catch(e) {} try { var loginHref = ctx + '/login/kakao'; loginHref += '?returnUrl=' + encodeURIComponent(location.pathname + (location.search || '')); window.location.href = loginHref; } catch(e){ window.location.href = ctx + '/login/kakao'; } } }); }

        function render(items){
            var $out = $('#readArea');
            $out.empty();
            if (!items || items.length === 0) { $out.html('<p style="color:#777;">위시한 책이 없습니다.</p>'); return; }
            var $table = $('<table class="result-table"></table>');
            items.forEach(function(item){
                var isbn = item.isbn || item.isbn13 || '';
                var $tr = $('<tr></tr>').attr('data-isbn', item.isbn || '').attr('data-isbn13', item.isbn13 || '');
                var $coverTd = $('<td class="info-cover"></td>');
                var href = isbn ? (ctx + '/book/view?isbn=' + encodeURIComponent(isbn)) : '#';
                var $a = $('<a class="mn-item-link"/>').attr('href', href);
                var $img = $('<img/>').attr('src', item.cover || item.thumbnail || '').attr('alt', item.title || '');
                $a.append($img); $coverTd.append($a);

                var $details = $('<td class="info-details"></td>');
                var $titleLink = $('<a class="mn-item-link"/>').attr('href', href).append($('<div class="info-title"></div>').text(item.title || '제목 없음'));
                $details.append($titleLink);
                var $meta = $('<div class="info-meta"></div>');
                $meta.append($('<div class="info-author"></div>').text(item.author || ''));
                $meta.append($('<div class="info-publisher-date"></div>').text((item.publisher||'') + (item.pubDate? ' | ' + item.pubDate : '')));
                $details.append($meta);

                var $actions = $('<div class="info-actions"></div>');
                var $rvwBtn = $('<button class="btn btn-rvw" type="button" aria-pressed="false" title="감상평">💬</button>');
                var $readBtn = $('<button class="btn btn-read" type="button" aria-pressed="false" title="읽음">📖</button>');
                var $wishBtn = $('<button class="btn btn-wish active" type="button" aria-pressed="true" title="위시리스트">💖</button>');
                $actions.append($rvwBtn).append($readBtn).append($wishBtn);
                $details.append($actions);

                $details.append('<input type="hidden" class="item-isbn" value="' + (item.isbn || '') + '">');
                $details.append('<input type="hidden" class="item-isbn13" value="' + (item.isbn13 || '') + '">');

                $tr.append($coverTd).append($details);
                $table.append($tr);
            });
            $out.append($table);

            try { markReviewButtons(items); } catch(e) { console.error('markReviewButtons error', e); }
            try { markWishButtons(items); } catch(e) { console.error('markWishButtons error', e); }
        }

        function markReviewButtons(items) {
            // Build payload from DOM rows (more robust for server-rendered or client-rendered tables)
            var payload = { isbns: [], isbns13: [] };
            $('#readArea table.result-table tr').each(function(){
                try {
                    var $tr = $(this);
                    var rIsbn = ($tr.attr('data-isbn') || $tr.find('.item-isbn').val() || '').toString().trim();
                    var rIsbn13 = ($tr.attr('data-isbn13') || $tr.find('.item-isbn13').val() || '').toString().trim();
                    if (rIsbn && rIsbn.length > 0) payload.isbns.push(rIsbn);
                    else if (rIsbn13 && rIsbn13.length > 0) payload.isbns13.push(rIsbn13);
                } catch (e) { /* ignore row parse errors */ }
            });

            function applyLocalStorageFallback() {
                $('#readArea table.result-table tr').each(function(){
                    var $tr = $(this);
                    var rIsbn = $tr.attr('data-isbn') || $tr.find('.item-isbn').val() || '';
                    var title = $tr.find('.info-title').text() || '';
                    var author = $tr.find('.info-author').text() || '';
                    var rawKey = (rIsbn && rIsbn.length) ? rIsbn : (title + '|' + author);
                    try {
                        if (localStorage.getItem(makeStorageKey('mn_like', rawKey)) === '1') {
                            $tr.find('.btn-rvw').addClass('active').attr('aria-pressed','true');
                        } else {
                            $tr.find('.btn-rvw').removeClass('active').attr('aria-pressed','false');
                        }
                    } catch(e) { }
                    try {
                        if (localStorage.getItem(makeStorageKey('mn_read', rawKey)) === '1') {
                            $tr.find('.btn-read').addClass('active').attr('aria-pressed','true');
                        } else {
                            $tr.find('.btn-read').removeClass('active').attr('aria-pressed','false');
                        }
                    } catch(e) { }
                    // NOTE: do not modify .btn-wish in wishlist fallback
                });
            }

            if ((payload.isbns.length===0) && (payload.isbns13.length===0)) {
                applyLocalStorageFallback();
                return;
            }

            // First check auth status to avoid server errors when unauthenticated
            $.get(ctx + '/auth/check').done(function(authResp){
                if (authResp !== 'OK') {
                    applyLocalStorageFallback();
                    return;
                }
                // Debug: payload
                try { console.debug('[markReviewButtons] payload', payload); } catch(e){}
                try {
                    var dbg = document.getElementById('mn_debug_out'); if (dbg) { dbg.style.display='block'; dbg.textContent = 'review payload:\n' + JSON.stringify(payload, null, 2) + '\n'; }
                } catch(e) {}

                $.ajax({
                    url: ctx + '/review/status',
                    type: 'POST',
                    dataType: 'json',
                    contentType: 'application/json; charset=UTF-8',
                    data: JSON.stringify(payload),
                    success: function(resp){
                        try {
                            try { console.debug('[markReviewButtons] resp', resp); } catch(e){}
                            try { var dbg = document.getElementById('mn_debug_out'); if (dbg) dbg.textContent += '\nreview resp:\n' + JSON.stringify(resp, null, 2) + '\n'; } catch(e){}
                            if (resp && resp.status === 'OK' && resp.data) {
                                $('#readArea table.result-table tr').each(function(){
                                    var $tr = $(this);
                                    var rIsbn = $tr.attr('data-isbn') || $tr.find('.item-isbn').val() || '';
                                    var rIsbn13 = $tr.attr('data-isbn13') || $tr.find('.item-isbn13').val() || '';
                                    var st = null;
                                    if (rIsbn && resp.data[rIsbn]) st = resp.data[rIsbn];
                                    if (!st && rIsbn13 && resp.data[rIsbn13]) st = resp.data[rIsbn13];
                                    if (!st) {
                                        var keys = Object.keys(resp.data || {});
                                        for (var i=0;i<keys.length;i++) { if (!st && resp.data[keys[i]] && keys[i] === rIsbn) st = resp.data[keys[i]]; }
                                    }

                                    var hasReview = false;
                                    var isRead = false;
                                    try {
                                        if (st) {
                                            if ((st.rating != null) || (st.cmnt && String(st.cmnt).trim().length>0) || (st.reviewText && String(st.reviewText).trim().length>0)) hasReview = true;
                                            // Normalize many possible forms for read flag
                                            var ryn = null;
                                            if (typeof st.readYn !== 'undefined') ryn = st.readYn;
                                            else if (typeof st.readYN !== 'undefined') ryn = st.readYN;
                                            else if (typeof st.READ_YN !== 'undefined') ryn = st.READ_YN;
                                            else if (typeof st.read !== 'undefined') ryn = st.read;
                                            else if (typeof st.READYN !== 'undefined') ryn = st.READYN;
                                            if (ryn != null) {
                                                try {
                                                    if (typeof ryn === 'boolean') isRead = !!ryn;
                                                    else {
                                                        var rstr = String(ryn).toUpperCase(); if (rstr === 'Y' || rstr === '1' || rstr === 'TRUE') isRead = true;
                                                    }
                                                } catch(e) { }
                                            }
                                        }
                                    } catch(e) { console.error('parse status object error', e); }

                                    try {
                                        var title = $tr.find('.info-title').text() || '';
                                        var author = $tr.find('.info-author').text() || '';
                                        var rawKey = (rIsbn && rIsbn.length) ? rIsbn : (title + '|' + author);
                                        if (!hasReview) {
                                            if (localStorage.getItem(makeStorageKey('mn_like', rawKey)) === '1') hasReview = true;
                                        }
                                        if (!isRead) {
                                            if (localStorage.getItem(makeStorageKey('mn_read', rawKey)) === '1') isRead = true;
                                        }
                                    } catch(e) {}

                                    try { if (hasReview) $tr.find('.btn-rvw').addClass('active').attr('aria-pressed','true'); else $tr.find('.btn-rvw').removeClass('active').attr('aria-pressed','false'); } catch(e) {}
                                    // Apply read state from server/localStorage only (do not touch wish button)
                                    try { if (isRead) $tr.find('.btn-read').addClass('active').attr('aria-pressed','true'); else $tr.find('.btn-read').removeClass('active').attr('aria-pressed','false'); } catch(e) {}
                                    // do NOT modify .btn-wish here for wishlist page; keep read/wish UI untouched
                                    
                                    // debug per-row
                                    try { var dbg = document.getElementById('mn_debug_out'); if (dbg) dbg.textContent += '\nrow: ' + (rIsbn||rIsbn13||title) + ' -> hasReview=' + hasReview + ', isRead=' + isRead + '\n'; } catch(e){}
                                });
                            } else {
                                // server responded but not OK: fallback to localStorage
                                applyLocalStorageFallback();
                            }
                        } catch(e){ console.error('markReviewButtons parse error', e); applyLocalStorageFallback(); }
                    },
                    error: function(){
                        applyLocalStorageFallback();
                    }
                });
            }).fail(function(){
                applyLocalStorageFallback();
            });
        }

        function markWishButtons(items) {
            if (!items || items.length === 0) return;
            var payload = { isbns: [], isbns13: [] };
            items.forEach(function(it){ if (it.isbn && String(it.isbn).trim().length>0) payload.isbns.push(String(it.isbn).trim()); else if (it.isbn13 && String(it.isbn13).trim().length>0) payload.isbns13.push(String(it.isbn13).trim()); });
            if ((payload.isbns.length===0) && (payload.isbns13.length===0)) {
                $('#readArea table.result-table tr').each(function(){ var $tr = $(this); var title = $tr.find('.info-title').text() || ''; var author = $tr.find('.info-author').text() || ''; var rawKey = title + '|' + author; try { if (localStorage.getItem(makeStorageKey('mn_wish', rawKey)) === '1') { $tr.find('.btn-wish').addClass('active').attr('aria-pressed','true'); } } catch(e) {} });
                return;
            }
            $.ajax({ url: ctx + '/wish/status', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify(payload), success: function(resp){ try { if (resp && resp.status === 'OK' && resp.data) { $('#readArea table.result-table tr').each(function(){ var $tr = $(this); var rIsbn = $tr.attr('data-isbn') || $tr.find('.item-isbn').val() || ''; var rIsbn13 = $tr.attr('data-isbn13') || $tr.find('.item-isbn13').val() || ''; var wished = false; if (rIsbn && (typeof resp.data[rIsbn] !== 'undefined')) wished = !!resp.data[rIsbn]; if (!wished && rIsbn13 && (typeof resp.data[rIsbn13] !== 'undefined')) wished = !!resp.data[rIsbn13]; if (!wished) { var title = $tr.find('.info-title').text() || ''; var author = $tr.find('.info-author').text() || ''; var rawKey = (rIsbn && rIsbn.length) ? rIsbn : (title + '|' + author); try { if (localStorage.getItem(makeStorageKey('mn_wish', rawKey)) === '1') wished = true; } catch(e) {} } if (wished) { try { $tr.find('.btn-wish').addClass('active').attr('aria-pressed','true'); } catch(e){} } else { try { $tr.find('.btn-wish').removeClass('active').attr('aria-pressed','false'); } catch(e){} } }); } } catch(e){ console.error('markWishButtons parse error', e); } }, error: function(){ } });
        }

        // Review / Read handlers and modal behavior (copied/adapted from index.jsp)
        var currentReviewItem = null;
        var currentLikeButton = null;

        // Open a blank review modal for a new review
        function openReviewModal(item, $btn) {
            if ((!item || Object.keys(item).length === 0) && $btn) {
                try {
                    var $row = $btn.closest('tr');
                    var domIsbn = $row.attr('data-isbn') || '';
                    var domIsbn13 = $row.attr('data-isbn13') || '';
                    var title = $row.find('.info-title').text() || '';
                    var author = $row.find('.info-author').text() || '';
                    item = item || {};
                    if (!item.isbn) item.isbn = domIsbn;
                    if (!item.isbn13) item.isbn13 = domIsbn13;
                    if (!item.title) item.title = title.trim();
                    if (!item.author) item.author = author.trim();
                } catch (e) { console.error('openReviewModal: failed to read from DOM', e); }
            }
            currentReviewItem = item;
            currentLikeButton = $btn;
            try { $('#rvw_rating').val(''); } catch(e){}
            try { $('#rvw_comnet').val(''); } catch(e){}
            try { $('#rvw_text').val(''); } catch(e){}
            try { $('#rvw_delete').hide(); } catch(e){}
            $('#reviewModal').css('display','flex').hide().fadeIn(200);
        }

        // Open modal for editing existing review (pre-fill fields when possible)
        function openEditReviewModal(itemObj, $btnRef, status) {
            try {
                var _rating = null, _cmnt = null, _reviewText = null;
                if (status) {
                    _rating = (typeof status.rating !== 'undefined') ? status.rating : (typeof status.RATING !== 'undefined' ? status.RATING : null);
                    _cmnt = (typeof status.cmnt !== 'undefined') ? status.cmnt : (typeof status.CMNT !== 'undefined' ? status.CMNT : (typeof status.comment !== 'undefined' ? status.comment : null));
                    _reviewText = (typeof status.reviewText !== 'undefined') ? status.reviewText : (typeof status.REVIEW_TEXT !== 'undefined' ? status.REVIEW_TEXT : (typeof status.text !== 'undefined' ? status.text : null));
                    try { if (_rating && typeof _rating === 'object' && _rating.value) _rating = _rating.value; } catch(e){}
                    try { if (_cmnt && typeof _cmnt === 'object' && _cmnt.value) _cmnt = _cmnt.value; } catch(e){}
                    try { if (_reviewText && typeof _reviewText === 'object' && _reviewText.value) _reviewText = _reviewText.value; } catch(e){}
                }

                if (status && (_rating != null || _cmnt != null || _reviewText != null)) {
                    var rv = (_rating != null && _rating !== '') ? String(_rating) : '';
                    if (rv) {
                        var $sel = $('#rvw_rating');
                        if ($sel.find('option[value="' + rv + '"]').length === 0) {
                            $sel.find('.temp-rv-option').remove();
                            $sel.append($('<option>').val(rv).text(rv).addClass('temp-rv-option'));
                        }
                        $sel.val(rv);
                        try { $sel.trigger('change'); } catch(e){}
                    } else { try { $('#rvw_rating').val(''); renderStars(''); } catch(e){} }
                    try { $('#rvw_comnet').val(_cmnt != null ? String(_cmnt) : ''); } catch(e){}
                    try { $('#rvw_text').val(_reviewText != null ? String(_reviewText) : ''); } catch(e){}
                    try { $('#rvw_delete').show(); } catch(e){}
                } else {
                    try { $('#rvw_delete').hide(); $('#rvw_comnet').val(''); $('#rvw_text').val(''); $('#rvw_rating').val(''); renderStars(''); } catch(e){}
                }

                currentReviewItem = itemObj;
                currentLikeButton = $btnRef;
                // open modal
                setTimeout(function(){ $('#reviewModal').css('display','flex').hide().fadeIn(200); }, 50);
            } catch (e) { console.error('openEditReviewModal error', e); openReviewModal(itemObj, $btnRef); }
        }

        function closeReviewModal() {
            $('#reviewModal').fadeOut(200, function(){ $(this).css('display','none'); try { $('#rvw_rating').find('.temp-rv-option').remove(); } catch(e){} currentReviewItem = null; currentLikeButton = null; });
        }

        // Delegated handler for review button in #readArea — always fetch review status and open edit modal if present
        $(document).on('click', '#readArea .btn-rvw', function(e){
            e.preventDefault();
            var $btn = $(this);
            var $row = $btn.closest('tr');
            var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
            var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
            var titleText = $row.find('.info-title').text() || '';
            var authorText = $row.find('.info-author').text() || '';
            var item = { isbn: domIsbn || '', isbn13: domIsbn13 || '', title: titleText.trim(), author: authorText.trim(), rawKey: (domIsbn && domIsbn.length) ? domIsbn : (titleText ? (titleText + '|' + authorText) : '') };
            var pendingItem = { isbn: item.isbn || '', isbn13: item.isbn13 || '', title: item.title || '', author: item.author || '', rawKey: item.rawKey };

            requireLoginThen(function(){
                try {
                    var payload = { isbns: [], isbns13: [] };
                    if (pendingItem.isbn && pendingItem.isbn.toString().trim().length > 0) payload.isbns.push(pendingItem.isbn.toString().trim());
                    if (pendingItem.isbn13 && pendingItem.isbn13.toString().trim().length > 0) payload.isbns13.push(pendingItem.isbn13.toString().trim());

                    // If no identifiers available, open blank modal (can't query server)
                    if ((payload.isbns.length === 0) && (payload.isbns13.length === 0)) {
                        openReviewModal(item, $btn);
                        return;
                    }

                    $.ajax({
                        url: ctx + '/review/status',
                        type: 'POST',
                        contentType: 'application/json; charset=UTF-8',
                        data: JSON.stringify(payload),
                        success: function(resp){
                            try {
                                var statusObj = null;
                                if (resp && resp.status === 'OK' && resp.data) {
                                    if (payload.isbns && payload.isbns.length > 0 && resp.data[payload.isbns[0]]) statusObj = resp.data[payload.isbns[0]];
                                    if (!statusObj && payload.isbns13 && payload.isbns13.length > 0 && resp.data[payload.isbns13[0]]) statusObj = resp.data[payload.isbns13[0]];
                                    if (!statusObj) {
                                        var keys = Object.keys(resp.data || {});
                                        if (keys && keys.length > 0) statusObj = resp.data[keys[0]];
                                    }
                                }
                                if (statusObj) openEditReviewModal(pendingItem, $btn, statusObj);
                                else openReviewModal(item, $btn);
                            } catch (e) {
                                console.error('btn-rvw success handler error', e);
                                openReviewModal(item, $btn);
                            }
                        },
                        error: function() {
                            // on error, open blank modal so user can create a review
                            openReviewModal(item, $btn);
                        }
                    });
                } catch (e) {
                    console.error('btn-rvw handler error', e);
                    openReviewModal(item, $btn);
                }
            }, { type: 'like', item: pendingItem });
        });

        // Read toggle for #readArea (similar to index.jsp handler)
        $(document).on('click', '#readArea .btn-read', function(e){
            e.preventDefault();
            var $btn = $(this);
            var $row = $btn.closest('tr');
            var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
            var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
            var rawKey = (domIsbn && domIsbn.length) ? domIsbn : ($row.find('.info-title').text() + '|' + $row.find('.info-author').text());
            var readKey = makeStorageKey('mn_read', rawKey);

            requireLoginThen(function() {
                var currentlyActive = $btn.hasClass('active');
                var desiredReadYn = currentlyActive ? 'N' : 'Y';
                var payload = { isbn: domIsbn, isbn13: domIsbn13, readYn: desiredReadYn };
                $.ajax({
                    url: ctx + '/review/read',
                    type: 'POST',
                    contentType: 'application/json; charset=UTF-8',
                    data: JSON.stringify(payload),
                    success: function(resp) {
                        try {
                            if (resp && resp.status === 'OK') {
                                if (desiredReadYn === 'Y') {
                                    $btn.addClass('active').attr('aria-pressed','true');
                                    try { localStorage.setItem(readKey, '1'); } catch(e){}
                                } else {
                                    $btn.removeClass('active').attr('aria-pressed','false');
                                    try { localStorage.removeItem(readKey); } catch(e){}
                                }
                            } else if (resp && resp.status === 'ERR' && resp.message === 'CANNOT_UNSET_READ_HAS_RATING') {
                                alert('이미 평점이나 리뷰가 등록되어 있어 읽음 표시를 취소할 수 없습니다. 먼저 리뷰를 삭제하거나 평점을 제거하세요.');
                            } else {
                                console.error('Failed to set read status', resp);
                                alert('읽음 상태 변경에 실패했습니다. 다시 시도해주세요.');
                            }
                        } catch (e) { console.error('read success handler error', e); alert('읽음 상태 변경 중 오류가 발생했습니다.'); }
                    },
                    error: function(xhr) { console.error('Read status AJAX error', xhr.status); alert('읽음 상태를 서버에 저장하지 못했습니다. 다시 시도해주세요.'); }
                });
            });
        });

        // Modal save/delete and helpers
        $('#rvw_cancel').on('click', function(){ closeReviewModal(); });

        $('#rvw_delete').on('click', function() {
            if (!currentReviewItem) { alert('삭제할 항목 정보가 없습니다.'); return; }
            if (!confirm('정말로 리뷰를 삭제하시겠습니까? 삭제하면 평점/한줄평/감상평이 모두 제거됩니다.')) return;
            var payload = { isbn: currentReviewItem.isbn || '', isbn13: currentReviewItem.isbn13 || '' };
            $.ajax({ url: ctx + '/review/delete', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify(payload), success: function(resp){ try { if (resp && resp.status === 'OK') { var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || '')); try { localStorage.removeItem(makeStorageKey('mn_like', rawKey)); } catch(e){} try { localStorage.removeItem(makeStorageKey('mn_read', rawKey)); } catch(e){} try { if (currentLikeButton && currentLikeButton.length) { currentLikeButton.removeClass('active').attr('aria-pressed','false'); try { currentLikeButton.closest('tr').find('.btn-read').removeClass('active').attr('aria-pressed','false'); } catch(e){} } } catch(e){} alert('리뷰가 삭제되었습니다.'); closeReviewModal(); } else { alert('리뷰 삭제에 실패했습니다. 다시 시도해주세요.'); } } catch(e){ console.error('delete handler error', e); alert('리뷰 삭제 중 오류가 발생했습니다.'); } }, error: function(xhr){ console.error('Delete AJAX error', xhr.status); alert('리뷰 삭제 요청을 서버에 전달하지 못했습니다. 다시 시도해주세요.'); } });
        });

        $('#rvw_save').on('click', function() {
            const rating = $('#rvw_rating').val();
            const comment = $('#rvw_comnet').val();
            const text = $('#rvw_text').val();

            if (!rating) {
                alert('평점을 선택해주세요.');
                return;
            }

            if (!currentReviewItem) {
                alert('리뷰할 항목 정보가 없습니다. 다시 시도해주세요.');
                return;
            }

            const itemIsbn = (currentReviewItem && (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10)) ? (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10) : '';
            const fallbackKey = (!itemIsbn && currentReviewItem) ? ((currentReviewItem.title || '') + '|' + (currentReviewItem.author || '')) : '';
            const reviewData = {
                itemId: itemIsbn,
                itemKey: fallbackKey,
                isbn: currentReviewItem && currentReviewItem.isbn ? currentReviewItem.isbn : '',
                isbn13: currentReviewItem && currentReviewItem.isbn13 ? currentReviewItem.isbn13 : '',
                title: currentReviewItem && currentReviewItem.title ? currentReviewItem.title : '',
                author: currentReviewItem && currentReviewItem.author ? currentReviewItem.author : '',
                rating: rating,
                comment: comment,
                text: text
            };

            // If neither an ISBN nor an item key is present, block
            if (( (!reviewData.itemId || reviewData.itemId.trim() === '') && (!reviewData.itemKey || reviewData.itemKey.trim() === '') )) {
                alert('도서 식별자(ISBN) 또는 항목 정보가 없습니다. 다시 시도해주세요.');
                return;
            }

            $.ajax({
                url: ctx + '/review/save',
                type: 'POST',
                contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
                data: $.param(reviewData),
                success: function(resp) {
                    try {
                        if (resp && resp.status === 'OK') {
                            // persist local like/read
                            var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || ''));
                            try { localStorage.setItem(makeStorageKey('mn_like', rawKey), '1'); } catch(e){}
                            try { localStorage.setItem(makeStorageKey('mn_read', rawKey), '1'); } catch(e){}

                            // Mark UI buttons
                            if (currentLikeButton && currentLikeButton.length) {
                                currentLikeButton.addClass('active').attr('aria-pressed','true');
                                try { currentLikeButton.closest('tr').find('.btn-read').addClass('active').attr('aria-pressed','true'); } catch(e){}
                            }

+                            // Immediately update per-row summary rating
+                            try {
+                                var savedRating = reviewData.rating;
+                                var disp = null;
+                                try { if (savedRating != null && String(savedRating).trim().length>0 && !isNaN(Number(savedRating))) disp = Number(savedRating).toFixed(1); } catch(e) { disp = null; }
+                                if (disp != null) {
+                                    var $target = null;
+                                    try { if (currentLikeButton && currentLikeButton.length) $target = currentLikeButton.closest('tr'); } catch(e){}
+                                    try { if ((!$target || $target.length===0) && currentReviewItem && currentReviewItem.isbn && currentReviewItem.isbn.length) $target = $("tr[data-isbn='" + currentReviewItem.isbn + "']"); } catch(e){}
+                                    try { if ($target && $target.length) $target.find('.summary-rating-val').first().text(disp); } catch(e){}
+                                }
+                            } catch(e) { console.error('wishList immediate rating update error', e); }
+
                            closeReviewModal();
                            alert('리뷰가 저장되었습니다.');
                            // reload page sections
                            loadWishList();
                        } else {
                            alert('리뷰 저장에 실패했습니다.');
                        }
                    } catch (e) { console.error('rvw_save success handler error', e); alert('리뷰 저장 중 오류가 발생했습니다.'); }
                },
                error: function(xhr) { console.error('review save AJAX error', xhr.status); alert('리뷰 저장 요청을 서버에 전달하지 못했습니다.'); }
            });
        });

        function renderStars(val) {
            var out = '';
            if (!val) { out = '☆☆☆☆☆'; }
            else { var num = Math.floor(Number(val)); for (var i=0;i<num;i++) out += '★'; for (var j=num;j<5;j++) out += '☆'; }
            var el = document.getElementById('starDisplay'); if (el) el.textContent = out + (val ? ('  ' + val) : '');
        }

        // wire up rating select and overlay/esc handlers
        (function(){
            var sel = document.getElementById('rvw_rating'); if (sel) sel.addEventListener('change', function(){ renderStars(this.value); });
            var overlay = document.getElementById('reviewModal'); if (overlay) overlay.addEventListener('click', function(e){ if (e.target === overlay) closeReviewModal(); });
            window.closeReviewModal = closeReviewModal;
            document.addEventListener('keydown', function(e){ if (e.key === 'Escape' || e.key === 'Esc') { var ov = document.getElementById('reviewModal'); if (ov && ov.style.display !== 'none') closeReviewModal(); } });
        })();

        // ensure modal close button (✕) works
        $(document).on('click', '.mn-modal-close', function(e){ e.preventDefault(); try { closeReviewModal(); } catch(err) { console.error('mn-modal-close handler error', err); } });

        // Fallback: native event listener for environments where jQuery delegation might not fire
        try {
            document.addEventListener('click', function(e){
                try {
                    var el = e.target;
                    if (!el) return;
                    var btn = el.closest ? el.closest('.mn-modal-close') : null;
                    if (!btn) return;
                    e.preventDefault();
                    try { closeReviewModal(); } catch(err) { console.error('native mn-modal-close handler error', err); }
                } catch(inner){ /* ignore */ }
            }, false);
        } catch(e) { /* ignore fallback registration errors */ }

        // Initialize review/wish/read button states for server-rendered table
        try {
            // run after a short delay to ensure DOM is fully parsed
            setTimeout(function(){
                try { markReviewButtons(); } catch(e) { console.error('markReviewButtons init error', e); }
                try { markWishButtons((typeof serverItems !== 'undefined' && serverItems) ? serverItems : []); } catch(e) { try { markWishButtons([]); } catch(e){} }
            }, 50);
        } catch(e) { console.error('initialization error', e); }
    })();
</script>
</body>
</html>
