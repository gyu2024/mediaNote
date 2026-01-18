<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediaNote - 검색</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<div class="container" style="position:relative;">
    <!-- small user badge (inline-styled so we don't modify global CSS) -->
    <div style="position:absolute; top:12px; right:14px; font-size:13px; line-height:1;">
        <% com.mn.cm.model.User _u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
           String displayNick = null;
           if (_u != null && _u.getNickname() != null) {
               String nick = _u.getNickname().trim();
               if (nick.length() == 1) displayNick = nick;
               else if (nick.length() == 2) displayNick = nick.substring(0,1) + "*";
               else {
                   StringBuilder sb = new StringBuilder();
                   sb.append(nick.charAt(0));
                   for (int i = 1; i < nick.length()-1; i++) sb.append('*');
                   sb.append(nick.charAt(nick.length()-1));
                   displayNick = sb.toString();
               }
           }
        %>
        <% if (displayNick != null) { %>
            <span style="background:#f1f7ff; color:#0366d6; font-weight:700; padding:4px 8px; border-radius:12px;">
                <%= displayNick %>
            </span>
            <a style="color:#0366d6; text-decoration:none; font-weight:700; margin: 0px 8px 0px ;" href="<%= request.getContextPath() %>/logout">로그아웃</a>
        <% } else { %>
            <a style="color:#0366d6; text-decoration:none; font-weight:700; margin: 0px 8px 0px ;" href="<%= request.getContextPath() %>/login/kakao">로그인</a>
        <% } %>
    </div>

    <div class="logo">MediaNote</div>
    
    <form id="searchForm">
        <div class="input-row">
            <select name="mediaType" id="mediaType">
                <option value="" selected disabled>선택</option>
                <option value="book">책</option>
                <option value="drama">드라마</option>
                <option value="movie">영화</option>
            </select>
            <input type="text" name="query" id="query" placeholder="검색어 입력 후 엔터" required autocomplete="off">
        </div>
    </form>
    
    <div id="resultArea"></div>
</div>

<!-- Review modal (modern design) -->
<div id="reviewModal" class="mn-modal-overlay" aria-hidden="true">
    <div class="mn-modal" role="dialog" aria-modal="true" aria-labelledby="mn-modal-title">
        <header class="mn-modal-header">
            <h3 id="mn-modal-title">리뷰 작성</h3>
            <button class="mn-modal-close" aria-label="닫기" onclick="closeReviewModal()">✕</button>
        </header>
        <section class="mn-modal-body">
            <div class="mn-row">
                <label class="mn-label">평점</label>
                <div class="mn-rating">
                    <div id="starDisplay" class="star-display" aria-hidden="true">★☆☆☆☆</div>
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
            <div class="mn-row">
                <div class="rating-guide-container">
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
                <label class="mn-label" for="rvw_text">감 상 평</label>
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
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script>
$(document).ready(function() {
    const contextPath = "${pageContext.request.contextPath}";
    const $searchForm = $('#searchForm');
    const $mediaType = $('#mediaType');
    const $query = $('#query');

    // makeStorageKey available globally in this ready scope (used by multiple callbacks)
    function makeStorageKey(prefix, rawKey) {
        try {
            return prefix + ':' + btoa(unescape(encodeURIComponent(rawKey)));
        } catch (e) {
            return prefix + ':' + rawKey;
        }
    }

    // helper: open the modal prefilled for editing an existing review (top-level so handlers can call it)
    function openEditReviewModal(itemObj, $btnRef, status) {
        try {
            console.debug('[openEditReviewModal] itemObj:', itemObj, 'status:', status);
             // ensure itemObj has identifiers if available from DOM
             var $row = $btnRef ? $btnRef.closest('tr') : null;
             if ($row && $row.length) {
                 if (!itemObj.isbn || itemObj.isbn.trim() === '') itemObj.isbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
                 if (!itemObj.isbn13 || itemObj.isbn13.trim() === '') itemObj.isbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
                 if (!itemObj.title) itemObj.title = $row.find('.info-title').text().trim();
                 if (!itemObj.author) itemObj.author = $row.find('.info-author').text().trim();
             }
 
             // prefill fields from status when present
             if (status) {
                var rv = '';
                if (status.rating != null && status.rating !== '') {
                    try {
                        var num = Number(status.rating);
                        if (!isNaN(num)) {
                            rv = num.toFixed(1); // format like "5.0", "4.5"
                        } else {
                            rv = String(status.rating);
                        }
                    } catch (e) { rv = String(status.rating); }
                }
                // set select to a value that exists in options (one-decimal format)
                try {
                    var $sel = $('#rvw_rating');
                    // if exact option missing, round to nearest 0.5 (e.g., 4.23 -> 4.0, 4.75 -> 5.0)
                    if (rv && $sel.find('option[value="' + rv + '"]').length === 0) {
                        var n = Number(rv);
                        if (!isNaN(n)) {
                            var rounded = Math.round(n * 2) / 2; // nearest 0.5
                            var candidate = rounded.toFixed(1);
                            if ($sel.find('option[value="' + candidate + '"]').length > 0) rv = candidate;
                            else {
                                // try floor to .0 or .5
                                var floor = (Math.floor(n) + (Math.floor((n - Math.floor(n)) * 2) / 2)).toFixed(1);
                                if ($sel.find('option[value="' + floor + '"]').length > 0) rv = floor;
                            }
                        }
                    }
                    // if still not available, create a temporary option so the select can show the exact value
                    if (rv && $('#rvw_rating').find('option[value="' + rv + '"]').length === 0) {
                        try {
                            // remove any previous temp option and append a fresh one for this session
                            $sel.find('.temp-rv-option').remove();
                            $sel.append($('<option>').val(rv).text(rv).addClass('temp-rv-option'));
                        } catch (e) { console.error('failed to append temp rating option', e); rv = ''; }
                    }
                    console.debug('[openEditReviewModal] rating options:', $('#rvw_rating').find('option').map(function(){return this.value;}).get(), 'chosen rv:', rv);
                    try {
                        $sel.val(rv);
                        // ensure the specific option is selected in all browsers
                        $sel.find('option').prop('selected', false);
                        var $opt = $sel.find('option[value="' + rv + '"]');
                        if ($opt.length > 0) {
                            $opt.prop('selected', true);
                        }
                        // double-check actual value and log
                        console.debug('[openEditReviewModal] after set select val:', $sel.val());
                        // trigger change so any listeners update
                        $sel.trigger('change');
                    } catch (e) { console.error('select set finalization error', e); }
                 } catch (e) { console.error('rating select set error', e); }
                $('#rvw_comnet').val(status.comnet != null ? String(status.comnet) : '');
                $('#rvw_text').val(status.reviewText != null ? String(status.reviewText) : '');
                renderStars(rv);
             } else {
                 $('#rvw_rating').val('');
                 $('#rvw_comnet').val('');
                 $('#rvw_text').val('');
                 renderStars('');
             }
 
             // set current state and open modal
             currentReviewItem = itemObj;
             currentLikeButton = $btnRef;
            // show delete button when editing an existing review (status provided), hide otherwise
            try { if (status) { $('#rvw_delete').show(); } else { $('#rvw_delete').hide(); } } catch (e) {}
             console.debug('[openEditReviewModal] prefills:', { rating: $('#rvw_rating').val(), comnet: $('#rvw_comnet').val(), text: $('#rvw_text').val() });
             $('#reviewModal').css('display','flex').hide().fadeIn(200);
         } catch (e) {
             console.error('openEditReviewModal error', e);
             // fallback to openReviewModal
             openReviewModal(itemObj, $btnRef);
         }
     }

    // 엔터키를 누르거나 폼이 제출될 때만 실행
    $searchForm.on('submit', function(e) {
        e.preventDefault(); // 페이지 새로고침 방지
        performSearch();
    });

    function performSearch() {
        const queryVal = $query.val().trim();
        const mediaTypeVal = $mediaType.val();

        if (!mediaTypeVal) {
            alert("카테고리를 먼저 선택해주세요.");
            return;
        }

        if (queryVal.length === 0) {
            return;
        }

        const formData = $searchForm.serialize();

        $.ajax({
            url: contextPath + "/hello",
            type: "GET",
            data: formData,
            success: function(response) {
                // predeclare reused variables to avoid ReferenceError due to hoisting or runtime oddities
                var $coverTd = null;
                var $img = null;
                 let items = (typeof response === "object") ? response : JSON.parse(response);
                
                if (!items || items.length === 0) {
                    $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>검색 결과가 없습니다.</p>");
                    return;
                }

                const $table = $("<table class='result-table'></table>");

                items.forEach(function(item) {
                    const rawKey = item.isbn && item.isbn.length ? item.isbn : (item.title + '|' + (item.author || ''));
                    const likeKey = makeStorageKey('mn_like', rawKey);
                    const readKey = makeStorageKey('mn_read', rawKey);

                    const liked = localStorage.getItem(likeKey) === '1';
                    const read = localStorage.getItem(readKey) === '1';

                    const $tr = $("<tr></tr>");
                    // store isbn/isbn13 on the row so the DOM always contains identifiers (hidden)
                    $tr.attr('data-isbn', item.isbn || '').attr('data-isbn13', item.isbn13 || '');

                    // details (create details first so image handlers can reference it safely)
                    const $detailsTd = $("<td class='info-details'></td>");
                    $detailsTd.append("<div class='info-title'>" + (item.title || '') + "</div>");
                    // move author + publisher/pubDate into a bottom-right meta block
                    const $metaDiv = $("<div class='info-meta'></div>");
                    $metaDiv.append("<div class='info-author'>" + (item.author || '') + "</div>");
                    $metaDiv.append("<div class='info-publisher-date'>" + (item.publisher || '') + " | " + (item.pubDate || '') + "</div>");
                    $detailsTd.append($metaDiv);

                    // actions (moved inside details)
                    const $actionsDiv = $("<div class='info-actions'></div>");
                    // emoji-only buttons (accessible via title/aria-label)
                    const $likeBtn = $("<button class='btn btn-like' type='button' aria-pressed='false' title='좋아요' aria-label='좋아요'>❤️</button>");
                    const $readBtn = $("<button class='btn btn-read' type='button' aria-pressed='false' title='읽음' aria-label='읽음'>📖</button>");

                    // apply initial state
                    if (liked) { $likeBtn.addClass('active').attr('aria-pressed','true'); }
                    if (read) { $readBtn.addClass('active').attr('aria-pressed','true'); }

                    // event handlers
                    // action: function to run when logged in. pending: optional object to save and resume after login.
                    function requireLoginThen(action, pending) {
                        $.get(contextPath + '/auth/check', function(resp) {
                            if (resp === 'OK') {
                                action();
                            } else {
                                // If a pending action is provided, save it so we can resume after login
                                try {
                                    if (pending) {
                                        localStorage.setItem('mn_pending_action', JSON.stringify(pending));
                                    }
                                    // Also save current search state (mediaType + query) so we can restore results after login
                                    try {
                                        var _searchState = { mediaType: $mediaType.val(), query: $query.val() };
                                        localStorage.setItem('mn_search_state', JSON.stringify(_searchState));
                                    } catch (e) { /* ignore storage errors */ }
                                } catch (e) { }
                                // redirect to Kakao login
                                window.location.href = contextPath + '/login/kakao';
                            }
                        });
                    }

                    $likeBtn.on('click', function() {
                        const $btn = $(this);
                        // build a compact pending item from DOM values so identifiers are preserved across redirect
                        var $row = $btn.closest('tr');
                        var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
                        var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
                        var titleText = $row.find('.info-title').text() || '';
                        var authorText = $row.find('.info-author').text() || '';
                        var pendingItem = {
                            isbn: domIsbn || '',
                            isbn13: domIsbn13 || '',
                            title: (item && item.title) ? item.title : titleText.trim(),
                            author: (item && item.author) ? item.author : authorText.trim(),
                            rawKey: (item && item.isbn) ? item.isbn : (item && item.title ? (item.title + '|' + (item.author||'')) : '')
                        };

                        // When not logged in, save the intended action so we can resume after login
                        requireLoginThen(function() {
                            // If not already liked, open review modal to collect rating/review first.
                            if (!$btn.hasClass('active')) {
                                openReviewModal(item, $btn);
                            } else {
                                // If already liked, open edit modal: fetch current review and prefill modal for editing
                                try {
                                    // build payload using both isbn and isbn13 when available (handle isbn10/13/hyphen variations)
                                    var payload = { isbns: [], isbns13: [] };
                                    if (pendingItem.isbn && pendingItem.isbn.toString().trim().length > 0) payload.isbns.push(pendingItem.isbn.toString().trim());
                                    if (pendingItem.isbn13 && pendingItem.isbn13.toString().trim().length > 0) payload.isbns13.push(pendingItem.isbn13.toString().trim());
                                     $.ajax({
                                        url: contextPath + '/review/status',
                                        type: 'POST',
                                        contentType: 'application/json; charset=UTF-8',
                                        data: JSON.stringify(payload),
                                        success: function(resp) {
                                            try {
                                                var statusObj = null;
                                                if (resp && resp.status === 'OK' && resp.data) {
                                                    // prefer exact isbn match
                                                    if (payload.isbns && payload.isbns.length > 0 && resp.data[payload.isbns[0]]) statusObj = resp.data[payload.isbns[0]];
                                                    // fallback to isbn13
                                                    if (!statusObj && payload.isbns13 && payload.isbns13.length > 0 && resp.data[payload.isbns13[0]]) statusObj = resp.data[payload.isbns13[0]];
                                                    // if still not found, try other keys in resp.data (first available)
                                                    if (!statusObj) {
                                                        var keys = Object.keys(resp.data || {});
                                                        if (keys && keys.length > 0) statusObj = resp.data[keys[0]];
                                                    }
                                                }
                                                openEditReviewModal(pendingItem, $btn, statusObj);
                                             } catch (e) { console.error('Failed to fetch review for edit', e); openEditReviewModal(pendingItem, $btn, null); }
                                         },
                                         error: function() { openEditReviewModal(pendingItem, $btn, null); }
                                     });
                                } catch (e) {
                                    console.error('Error opening edit modal', e);
                                    openEditReviewModal(pendingItem, $btn, null);
                                }
                            }
                        }, { type: 'like', item: pendingItem });
                    });

                    $readBtn.on('click', function() {
                        const $btn = $(this);
                        // build item identifiers from DOM
                        var $row = $btn.closest('tr');
                        var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
                        var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';

                        requireLoginThen(function() {
                            // desired state: if currently active, we want to unset (N), otherwise set (Y)
                            var currentlyActive = $btn.hasClass('active');
                            var desiredReadYn = currentlyActive ? 'N' : 'Y';

                            var payload = { isbn: domIsbn, isbn13: domIsbn13, readYn: desiredReadYn };
                            $.ajax({
                                url: contextPath + '/review/read',
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
                                            // Specific user-friendly message: can't unset read if rating/comment/review exists
                                            alert('이미 평점이나 리뷰가 등록되어 있어 읽음 표시를 취소할 수 없습니다. 먼저 리뷰를 삭제하거나 평점을 제거하세요.');
                                        } else {
                                            console.error('Failed to set read status', resp);
                                            alert('읽음 상태 변경에 실패했습니다. 다시 시도해주세요.');
                                        }
                                    } catch (e) { console.error('read success handler error', e); alert('읽음 상태 변경 중 오류가 발생했습니다.'); }
                                },
                                error: function(xhr) {
                                    console.error('Read status AJAX error', xhr.status);
                                    alert('읽음 상태를 서버에 저장하지 못했습니다. 다시 시도해주세요.');
                                }
                            });
                        });
                    });

                    $actionsDiv.append($likeBtn).append($readBtn);

                    $detailsTd.append($actionsDiv);
                    // include hidden inputs for isbn/isbn13 inside details for easy access if needed
                    $detailsTd.append('<input type="hidden" class="item-isbn" value="' + (item.isbn || '') + '">');
                    $detailsTd.append('<input type="hidden" class="item-isbn13" value="' + (item.isbn13 || '') + '">');
                    
                    // create cover cell and image (ensure $coverTd exists before appending)
                    var $coverTd = $("<td class='info-cover'></td>");
                    var $img = $("<img>").attr('src', item.cover || '');
                    // when image loads, set details min-height to match image height
                    $img.on('load', function() {
                        try {
                            const imgH = $(this).height();
                            if (imgH && imgH > 0) {
                                $detailsTd.css('min-height', (160) + 'px');
                            } else {
                            	$detailsTd.css('min-height', (160) + 'px');
                            }
                        } catch (e) {}
                    });
                    // if image errors, set a sane default min-height
                    $img.on('error', function(){
                        $detailsTd.css('min-height', '90px');
                    });
                    $coverTd.append($img);
                    // handle cached images (apply after DOM insertion)
                    setTimeout(function(){
                        try {
                            if ($img[0] && $img[0].complete && $img[0].naturalHeight) {
                                const imgH = $img[0].naturalHeight;
                                if (imgH && imgH > 0) {
                                    $detailsTd.css('min-height', (160) + 'px');
                                } else {
                                	$detailsTd.css('min-height', (160) + 'px');
                                }
                            }
                        } catch(e){}
                    }, 0);

                    // defensive: ensure $coverTd exists (avoid ReferenceError if code ran unexpectedly)
                    if (typeof $coverTd === 'undefined' || $coverTd == null) {
                        $coverTd = $("<td class='info-cover'></td>");
                        $coverTd.append($("<img>").attr('src', ''));
                    }
                    $tr.append($coverTd).append($detailsTd);
                    $table.append($tr);
                });

                $('#resultArea').html($table);
                
                // Query server for review statuses (read/like) for the current user and the rendered items
                try {
                    var isbns = [];
                    var isbns13 = [];
                    items.forEach(function(it){
                        if (it && it.isbn && it.isbn.toString().trim().length>0) isbns.push(it.isbn.toString());
                        if (it && it.isbn13 && it.isbn13.toString().trim().length>0) isbns13.push(it.isbn13.toString());
                    });

                    if ((isbns && isbns.length>0) || (isbns13 && isbns13.length>0)) {
                        $.ajax({
                            url: contextPath + '/review/status',
                            type: 'POST',
                            contentType: 'application/json; charset=UTF-8',
                            data: JSON.stringify({ isbns: isbns, isbns13: isbns13 }),
                            success: function(resp) {
                                try {
                                    if (resp && resp.status === 'OK' && resp.data) {
                                        var map = resp.data;
                                        // helper: normalize isbn-like keys to digits-only for robust comparison
                                        function normKey(s) { try { return String(s||'').replace(/\D/g,''); } catch(e) { return String(s||''); } }
                                        // build a lookup of normalized identifiers -> first matching row
                                        var rowLookup = {};
                                        $('#resultArea .result-table tr').each(function(){
                                            var $r = $(this);
                                            var a = ($r.attr('data-isbn') || '').toString();
                                            var b = ($r.attr('data-isbn13') || '').toString();
                                            var na = normKey(a);
                                            var nb = normKey(b);
                                            if (na && na.length>0) rowLookup[na] = $r;
                                            if (nb && nb.length>0) rowLookup[nb] = $r;
                                        });

                                        Object.keys(map).forEach(function(k){
                                            var st = map[k];
                                            var nk = normKey(k);
                                            var $row = rowLookup[nk];
                                            // fallback: try direct attribute match if normalized failed
                                            if ((!$row || $row.length === 0) && $("tr[data-isbn='"+k+"']").length) $row = $("tr[data-isbn='"+k+"']");
                                            if ((!$row || $row.length === 0) && $("tr[data-isbn13='"+k+"']").length) $row = $("tr[data-isbn13='"+k+"']");
                                            if ($row && $row.length > 0) {
                                                var $likeBtnRow = $row.find('.btn-like').first();
                                                var $readBtnRow = $row.find('.btn-read').first();
                                                // compute rawKey for localStorage: prefer shown isbn, else title|author
                                                var shownIsbn = $row.attr('data-isbn') && $row.attr('data-isbn').length ? $row.attr('data-isbn') : '';
                                                var rawKey = shownIsbn.length ? shownIsbn : ($row.find('.info-title').text().trim() + '|' + ($row.find('.info-author').text().trim() || ''));
                                                // read status
                                                if (st.readYn && String(st.readYn) === 'Y') {
                                                    if ($readBtnRow && $readBtnRow.length) { $readBtnRow.addClass('active').attr('aria-pressed','true'); }
                                                    try { localStorage.setItem(makeStorageKey('mn_read', rawKey), '1'); } catch(e){}
                                                }
                                                // like status: consider presence of rating/comnet/review as liked
                                                if ((st.rating != null && String(st.rating).trim() !== '') || (st.comnet != null && String(st.comnet).trim() !== '') || (st.reviewText != null && String(st.reviewText).trim() !== '')) {
                                                    if ($likeBtnRow && $likeBtnRow.length) { $likeBtnRow.addClass('active').attr('aria-pressed','true'); }
                                                    try { localStorage.setItem(makeStorageKey('mn_like', rawKey), '1'); } catch(e){}
                                                }
                                            }
                                        });
                                     }
                                 } catch (e) { console.error('Failed to apply review statuses', e); }
                             },
                            error: function(xhr) {
                                // ignore silently; status check is optional
                                console.error('Failed to fetch review statuses', xhr.status);
                            }
                        });
                    }
                } catch (e) { console.error('Error preparing status request', e); }

                 // After inserting into DOM, ensure already-loaded images set details height
                 $('#resultArea .result-table tr').each(function() {
                    try {
                        const $row = $(this);
                        const $img = $row.find('.info-cover img');
                        const $details = $row.find('.info-details');
                        if ($img.length && $img[0].complete) {
                            if (h && h > 0) $details.css('min-height', (160) + 'px');
                        }
                    } catch (e) {}
                });
            },
            error: function(xhr) {
                console.error("에러 발생:", xhr.status);
            }
        });
    }

    // Review modal handlers
    let currentReviewItem = null;
    let currentLikeButton = null;

    function openReviewModal(item, $btn) {
        // If item missing (e.g., restored from pending or button-based), try to read identifiers from the DOM button/row
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
            } catch (e) {
                console.error('openReviewModal: failed to read item from DOM', e);
            }
        }

        currentReviewItem = item;
        currentLikeButton = $btn;
        $('#rvw_rating').val('');
        $('#rvw_comnet').val('');
        $('#rvw_text').val('');
        // ensure the overlay uses flex layout so centering works, then fade in
        $('#reviewModal').css('display','flex').hide().fadeIn(200);
    }

    function closeReviewModal() {
        // fade out and clear state after animation completes
        $('#reviewModal').fadeOut(200, function(){
            $(this).css('display','none');
            // remove any temporary rating options left behind
            try { $('#rvw_rating').find('.temp-rv-option').remove(); } catch(e){}
            currentReviewItem = null;
            currentLikeButton = null;
        });
    }

    $('#rvw_cancel').on('click', function() {
        closeReviewModal();
    });

    // Delete handler: visible when editing an existing review
    $('#rvw_delete').on('click', function() {
        if (!currentReviewItem) { alert('삭제할 항목 정보가 없습니다.'); return; }
        if (!confirm('정말로 리뷰를 삭제하시겠습니까? 삭제하면 평점/한줄평/감상평이 모두 제거됩니다.')) return;
        var payload = { isbn: currentReviewItem.isbn || '', isbn13: currentReviewItem.isbn13 || '' };
        $.ajax({
            url: contextPath + '/review/delete',
            type: 'POST',
            contentType: 'application/json; charset=UTF-8',
            data: JSON.stringify(payload),
            success: function(resp) {
                try {
                    if (resp && resp.status === 'OK') {
                        // remove like/read localStorage and update UI
                        var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || ''));
                        try { localStorage.removeItem(makeStorageKey('mn_like', rawKey)); } catch(e){}
                        try { localStorage.removeItem(makeStorageKey('mn_read', rawKey)); } catch(e){}
                        if (currentLikeButton) { currentLikeButton.removeClass('active').attr('aria-pressed','false'); }
                        alert('리뷰가 삭제되었습니다.');
                        closeReviewModal();
                    } else {
                        alert('리뷰 삭제에 실패했습니다. 다시 시도해주세요.');
                    }
                } catch (e) { console.error('delete success handler error', e); alert('리뷰 삭제 중 오류가 발생했습니다.'); }
            },
            error: function(xhr) {
                console.error('Delete AJAX error', xhr.status);
                alert('리뷰 삭제 요청을 서버에 전달하지 못했습니다. 다시 시도해주세요.');
            }
        });
    });


    $('#rvw_save').on('click', function() {
        const rating = $('#rvw_rating').val();
        const comment = $('#rvw_comnet').val();
        const text = $('#rvw_text').val();

        if (!rating) {
            alert('평점을 선택해주세요.');
            return;
        }

        // Ensure we have an item to review. If not, abort to avoid server-side MISSING_ISBN.
        if (!currentReviewItem) {
            alert('리뷰할 항목 정보가 없습니다. 다시 시도해주세요.');
            return;
        }

        // Prepare review data: send actual ISBN into itemId only; send a separate itemKey for fallback (title|author)
        const itemIsbn = (currentReviewItem && (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10)) ? (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10) : '';
        const fallbackKey = (!itemIsbn && currentReviewItem) ? ((currentReviewItem.title || '') + '|' + (currentReviewItem.author || '')) : '';
        const reviewData = {
            itemId: itemIsbn, // only actual ISBN (or empty)
            itemKey: fallbackKey, // title|author fallback (may be empty)
            isbn: currentReviewItem && currentReviewItem.isbn ? currentReviewItem.isbn : '',
            isbn13: currentReviewItem && currentReviewItem.isbn13 ? currentReviewItem.isbn13 : '',
            title: currentReviewItem && currentReviewItem.title ? currentReviewItem.title : '',
            author: currentReviewItem && currentReviewItem.author ? currentReviewItem.author : '',
            rating: rating,
            comment: comment,
            text: text
        };

        // If neither a true ISBN nor an itemKey (title) is available, stop and ask user to retry/search the book first.
        if ((!reviewData.itemId || reviewData.itemId.trim() === '') && (!reviewData.itemKey || reviewData.itemKey.trim() === '')) {
            alert('도서 식별자(ISBN) 또는 항목 정보가 없습니다. 검색에서 해당 항목을 선택한 뒤 다시 시도해주세요.');
            return;
        }

        console.log('Submitting reviewData:', reviewData);

        // Send review data to server (form-encoded to be compatible with server fallback)
        $.ajax({
            url: contextPath + "/review/save",
            type: "POST",
            contentType: "application/x-www-form-urlencoded; charset=UTF-8",
            data: $.param(reviewData),
            success: function(response) {
                // On success: close modal, persist like state and update button UI
                const rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || ''));
                const likeKey = makeStorageKey('mn_like', rawKey);
                const readKey = makeStorageKey('mn_read', rawKey);
                // persist like and read state locally
                try { localStorage.setItem(likeKey, '1'); } catch(e) {}
                try { localStorage.setItem(readKey, '1'); } catch(e) {}

                // update UI: activate the like button (if available) and the read button in the same row
                try {
                    if (currentLikeButton) {
                        currentLikeButton.addClass('active').attr('aria-pressed', 'true');
                        try {
                            var $row = currentLikeButton.closest('tr');
                            var $readBtn = $row.find('.btn-read').first();
                            if ($readBtn && $readBtn.length) $readBtn.addClass('active').attr('aria-pressed','true');
                        } catch (e) { /* ignore */ }
                    } else {
                        // fallback: try to locate row by ISBN/ISBN13 or title and set read button active
                        try {
                            if (currentReviewItem && currentReviewItem.isbn && currentReviewItem.isbn.length) {
                                var $r = $("tr[data-isbn='" + currentReviewItem.isbn + "']");
                                if ($r && $r.length) { $r.find('.btn-read').first().addClass('active').attr('aria-pressed','true'); }
                            } else if (currentReviewItem && currentReviewItem.isbn13 && currentReviewItem.isbn13.length) {
                                var $r2 = $("tr[data-isbn13='" + currentReviewItem.isbn13 + "']");
                                if ($r2 && $r2.length) { $r2.find('.btn-read').first().addClass('active').attr('aria-pressed','true'); }
                            } else if (currentReviewItem && currentReviewItem.title) {
                                $('#resultArea .result-table tr').each(function(){
                                    var $rr = $(this);
                                    var t = $rr.find('.info-title').text().trim();
                                    if (t === (currentReviewItem.title || '').trim()) {
                                        $rr.find('.btn-read').first().addClass('active').attr('aria-pressed','true');
                                    }
                                });
                            }
                        } catch (e) { }
                    }
                } catch (e) { console.error('Error updating like/read UI', e); }

                closeReviewModal();
                alert('리뷰가 저장되었습니다.');
            },
            error: function(xhr) {
                console.error("리뷰 저장 에러:", xhr.status);
                alert('리뷰 저장 중 오류가 발생했습니다. 나중에 다시 시도해주세요.');
            }
        });
    });

    // small helper: render star display based on select value
    function renderStars(val) {
        var out = '';
        if (!val) { out = '☆☆☆☆☆'; }
        else {
            var num = Math.floor(Number(val));
            for (var i=0;i<num;i++) out += '★';
            for (var j=num;j<5;j++) out += '☆';
        }
        var el = document.getElementById('starDisplay'); if (el) el.textContent = out + (val ? ('  ' + val) : '');
    }

    // wire up rating select and overlay/esc handlers (run now since we're in jQuery ready)
    (function(){
        var sel = document.getElementById('rvw_rating');
        if (sel) sel.addEventListener('change', function(){ renderStars(this.value); });

        // close when clicking overlay outside modal
        var overlay = document.getElementById('reviewModal');
        if (overlay) overlay.addEventListener('click', function(e){ if (e.target === overlay) closeReviewModal(); });

        // expose for inline onclick attribute and external callers
        window.closeReviewModal = closeReviewModal;

        // ESC to close modal when open
        document.addEventListener('keydown', function(e){
            if (e.key === 'Escape' || e.key === 'Esc') {
                var ov = document.getElementById('reviewModal');
                if (ov && ov.style.display !== 'none') closeReviewModal();
            }
        });
    })();
    
    // After page load, check if there is a pending action (stored before redirecting to login)
     try {
        // 1) Restore any saved search state so the user's search remains after login
        var savedSearchRaw = localStorage.getItem('mn_search_state');
        if (savedSearchRaw) {
            try {
                var saved = JSON.parse(savedSearchRaw);
                // Re-populate form fields if available
                if (saved && (saved.mediaType || saved.query)) {
                    try { if (saved.mediaType) $mediaType.val(saved.mediaType); } catch(e){}
                    try { if (saved.query) $query.val(saved.query); } catch(e){}
                    // Run the search to restore results (only if user is already logged-in)
                    // We'll check login status below and trigger performSearch when appropriate.
                }
            } catch (e) { console.error('Failed to parse saved search state', e); }
        }

        // 2) Restore any pending action saved before redirecting to login
        var pendingRaw = localStorage.getItem('mn_pending_action');
        if (pendingRaw) {
            // Remove it immediately to avoid double-processing
            localStorage.removeItem('mn_pending_action');
            var pending = JSON.parse(pendingRaw);
            console.log("%c [REVIEW] pending restored:", "color: blue; font-weight: bold;", pending);
        }

        // Verify user is logged in and then restore UI state: run search and resume pending action if present
        $.get(contextPath + '/auth/check', function(resp) {
            if (resp === 'OK') {
                // If we had a saved search, perform it now to restore results
                try {
                    var ss = localStorage.getItem('mn_search_state');
                    if (ss) {
                        try {
                            var sObj = JSON.parse(ss);
                            if (sObj && (sObj.mediaType || sObj.query)) {
                                try { if (sObj.mediaType) $mediaType.val(sObj.mediaType); } catch(e){}
                                try { if (sObj.query) $query.val(sObj.query); } catch(e){}
                                // run search to repopulate results
                                performSearch();
                            }
                        } catch (e) { console.error('Error parsing saved search on restore', e); }
                        // remove saved search state after restoring
                        try { localStorage.removeItem('mn_search_state'); } catch(e){}
                    }
                } catch (e) { console.error('Error restoring saved search', e); }

                // If there was a pending action, try to resume it (e.g., open review modal)
                try {
                    if (typeof pending !== 'undefined' && pending) {
                        // If pending a like action, open the review modal for that item
                        if (pending.type === 'like' && pending.item) {
                            // try to locate the row and simulate opening edit modal flow: first attempt to fetch status then open modal
                            var pItem = pending.item;
                            var payload = { isbns: [], isbns13: [] };
                            if (pItem.isbn && pItem.isbn.toString().trim().length > 0) payload.isbns.push(pItem.isbn.toString().trim());
                            if (pItem.isbn13 && pItem.isbn13.toString().trim().length > 0) payload.isbns13.push(pItem.isbn13.toString().trim());
                            $.ajax({
                                url: contextPath + '/review/status',
                                type: 'POST',
                                contentType: 'application/json; charset=UTF-8',
                                data: JSON.stringify(payload),
                                success: function(resp) {
                                    var statusObj = null;
                                    try {
                                        if (resp && resp.status === 'OK' && resp.data) {
                                            if (payload.isbns && payload.isbns.length > 0 && resp.data[payload.isbns[0]]) statusObj = resp.data[payload.isbns[0]];
                                            if (!statusObj && payload.isbns13 && payload.isbns13.length > 0 && resp.data[payload.isbns13[0]]) statusObj = resp.data[payload.isbns13[0]];
                                            if (!statusObj) {
                                                var keys = Object.keys(resp.data || {});
                                                if (keys && keys.length > 0) statusObj = resp.data[keys[0]];
                                            }
                                        }
                                    } catch (e) { }
                                    openEditReviewModal(pItem, null, statusObj);
                                },
                                error: function() { openEditReviewModal(pItem, null, null); }
                            });
                        }
                    }
                } catch (e) { console.error('Failed to resume pending action', e); }

                // Small confirmation that login succeeded (optional)
                try { alert('로그인에 성공했습니다!'); } catch(e){}
            } else {
                // not logged in; nothing to restore right now
            }
        });
         
    } catch (e) { console.error('Error processing pending action', e); }
});
</script>
</body>
</html>
