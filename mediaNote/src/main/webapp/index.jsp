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

<%-- include common header partial (user badge + logo) placed outside .container so sticky attaches to viewport --%>
<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />

<form id="searchForm" class="search-bar">
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

<div class="container" style="position:relative;">
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
                <label class="mn-label" for="rvw_text">감 상 평</label>
                <textarea id="rvw_text" placeholder="감상평을 입력하세요 (생략 가능)" maxlength="2000" class="mn-textarea"></textarea>
            </div>
            <!-- hidden inputs to hold item identifiers for modal actions -->
            <input type="hidden" id="rvw_item_isbn" value="" />
            <input type="hidden" id="rvw_item_isbn10" value="" />
            <input type="hidden" id="rvw_item_title" value="" />
            <input type="hidden" id="rvw_item_author" value="" />
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

    // Helper: robustly extract a status object for a given item from the response map
    function findStatusForItem(respData, item) {
        try {
            if (!respData) return null;
            // If respData is an array, try to match by isbn/isbn13
            if (Array.isArray(respData)) {
                for (var i = 0; i < respData.length; i++) {
                    var v = respData[i];
                    if (!v) continue;
                    if (item.isbn && (v.isbn === item.isbn || v.ISBN === item.isbn)) return v;
                    if (item.isbn13 && (v.isbn13 === item.isbn13 || v.ISBN13 === item.isbn13)) return v;
                }
                return respData.length > 0 ? respData[0] : null;
            }
            // If it's an object keyed by ISBN/ISBN13, try direct lookup
            if (typeof respData === 'object') {
                if (item.isbn && respData[item.isbn]) return respData[item.isbn];
                if (item.isbn13 && respData[item.isbn13]) return respData[item.isbn13];
                // fallback: iterate values and attempt to match fields inside
                for (var k in respData) {
                    if (!respData.hasOwnProperty(k)) continue;
                    var v = respData[k];
                    if (!v) continue;
                    try {
                        if (item.isbn && ((v.isbn && String(v.isbn) === String(item.isbn)) || (v.ISBN && String(v.ISBN) === String(item.isbn)))) return v;
                        if (item.isbn13 && ((v.isbn13 && String(v.isbn13) === String(item.isbn13)) || (v.ISBN13 && String(v.ISBN13) === String(item.isbn13)))) return v;
                    } catch (e) {}
                }
                // return first entry if nothing matched
                var keys = Object.keys(respData);
                if (keys && keys.length > 0) return respData[keys[0]];
            }
        } catch (e) { console.error('findStatusForItem error', e); }
        return null;
    }

    // Ensure modal helpers exist early so event handlers can safely call them even if definitions appear later
    try {
        if (typeof window.openEditReviewModal !== 'function') window.openEditReviewModal = function(item, btn, status){ console.warn('openEditReviewModal not yet defined - fallback'); openReviewModal && typeof openReviewModal === 'function' ? openReviewModal(item, btn) : null; };
        if (typeof window.openReviewModal !== 'function') window.openReviewModal = function(item, btn){ console.warn('openReviewModal not yet defined - fallback'); };
        if (typeof window.closeReviewModal !== 'function') window.closeReviewModal = function(){ console.warn('closeReviewModal not yet defined - fallback'); };
    } catch(e) {}
    // Flag to avoid double-restoring the saved search
    let restoredSearchDone = false;
    let initialBestsellerLoaded = false;

    // Save current search state to localStorage so detail navigation or login redirects can restore it
    function saveSearchState() {
        try {
            var _searchState = { mediaType: $mediaType.val(), query: $query.val() };
            localStorage.setItem('mn_search_state', JSON.stringify(_searchState));
        } catch (e) { /* ignore storage errors */ }
    }

    // Restore saved search state when page is shown (covers bfcache/back navigation)
    window.addEventListener('pageshow', function(e) {
        try { console.debug('[pageshow] fired, persisted=', e && e.persisted); } catch(e){}
        try {
            var ss = localStorage.getItem('mn_search_state');
            if (ss && !restoredSearchDone) {
                try {
                    var sObj = JSON.parse(ss);
                    if (sObj && (sObj.mediaType || sObj.query)) {
                        try { if (sObj.mediaType) $mediaType.val(sObj.mediaType); } catch(e){}
                        try { if (sObj.query) $query.val(sObj.query); } catch(e){}
                        performSearch();
                        restoredSearchDone = true;
                        try { localStorage.removeItem('mn_search_state'); } catch(e){}
                    }
                    else {
                        // No saved search state: load default bestsellers once on initial page view
                        if (!initialBestsellerLoaded) {
                            fetchBestsellers();
                            initialBestsellerLoaded = true;
                        }
                   }
                } catch (e) { console.error('pageshow restore error', e); }
            }
            else {
                // if there was no saved state at all (first visit), load bestsellers
                if (!ss && !initialBestsellerLoaded) {
                    fetchBestsellers();
                    initialBestsellerLoaded = true;
                }
            }
        } catch (e) {}
    });

    // Fetch bestsellers from server and render using the same item rendering logic as performSearch success
    function fetchBestsellers() {
        try {
            try { console.debug('[fetchBestsellers] called'); } catch(e){}
            $.ajax({
                url: contextPath + '/bestseller',
                type: 'GET',
                data: { MaxResults: 10, SearchTarget: 'Book' },
                success: function(response) {
                    try {
                        try { console.debug('[fetchBestsellers] raw response:', response); } catch(e){}
                        var items = (typeof response === "object") ? response : JSON.parse(response);
                        renderSearchResults(items);
                    } catch (e) { console.error('bestseller render error', e); }
                },
                error: function(xhr) { console.error('[베스트셀러] 호출 실패', xhr.status); }
            });
        } catch (e) { console.error('fetchBestsellers error', e); }
    }

    // Full renderer reused by both search and bestseller responses. This duplicates the original performSearch success logic
    // so that bestseller results include the same actions and per-row review/read/rating summary behavior.
    function renderSearchResults(items) {
        if (!items || !Array.isArray(items)) items = [];
        try {
            items = items.filter(function(it){ try { return it && it.isbn13 && it.isbn13.toString().trim().length > 0; } catch(e){ return false; } });
        } catch (e) {}

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
            $tr.attr('data-isbn', item.isbn || '').attr('data-isbn13', item.isbn13 || '');

            const $detailsTd = $("<td class='info-details'></td>");
            var detailIsbn = (item.isbn && item.isbn.toString().trim().length>0) ? item.isbn : ((item.isbn13 && item.isbn13.toString().trim().length>0) ? item.isbn13 : '');
            var detailUrl = contextPath + '/book/view?isbn=' + encodeURIComponent(detailIsbn);
            var $titleLink = $("<a class='mn-item-link' role='link' tabindex='0' href='" + detailUrl + "'></a>");
            $titleLink.append("<div class='info-title'>" + (item.title || '') + "</div>");
            $detailsTd.append($titleLink);

            const $metaDiv = $("<div class='info-meta'></div>");
            var $metaLink = $("<a class='mn-item-link' role='link' tabindex='0' href='" + detailUrl + "'></a>");
            $metaLink.append("<div class='info-author'>" + (item.author || '') + "</div>");
            $metaLink.append("<div class='info-publisher-date'>" + (item.publisher || '') + " | " + (item.pubDate || '') + "</div>");
            $metaDiv.append($metaLink);
            $detailsTd.append($metaDiv);

            const $actionsDiv = $("<div class='info-actions'></div>");
            const $likeBtn = $("<button class='btn btn-rvw' type='button' aria-pressed='false' title='감상평' aria-label='감상평'>💬</button>");
            const $readBtn = $("<button class='btn btn-read' type='button' aria-pressed='false' title='읽음' aria-label='읽음'>📖</button>");
            if (liked) { $likeBtn.addClass('active').attr('aria-pressed','true'); }
            if (read) { $readBtn.addClass('active').attr('aria-pressed','true'); }

            $actionsDiv.append("<span class='summary-badge' title='평균 평점' style='margin-right:8px;'><span>평점 : </span> <span class='big summary-rating-val'>-</span></span>");
            $actionsDiv.append($likeBtn);
            $actionsDiv.append($readBtn);
            var $wishBtn = $("<button class='btn btn-wish' type='button' aria-pressed='false' title='위시리스트' aria-label='위시리스트'>💖</button>");
            try { if (localStorage.getItem(makeStorageKey('mn_wish', rawKey)) === '1') { $wishBtn.addClass('active').attr('aria-pressed','true'); } } catch(e){}
            $actionsDiv.append($wishBtn);

            $detailsTd.append($actionsDiv);
            $detailsTd.append('<input type="hidden" class="item-isbn" value="' + (item.isbn || '') + '">');
            $detailsTd.append('<input type="hidden" class="item-isbn13" value="' + (item.isbn13 || '') + '">');

            var $coverTd = $("<td class='info-cover'></td>");
            var $coverLink = $("<a class='mn-item-link' href='" + detailUrl + "'></a>");
            var $img = $("<img>").attr('src', item.cover || '');
            $img.on('load', function(){ try { const imgH = $(this).height(); if (imgH && imgH>0) $detailsTd.css('min-height', '160px'); } catch(e){} });
            $img.on('error', function(){ $detailsTd.css('min-height', '90px'); });
            $coverLink.append($img);
            $coverTd.append($coverLink);

            $tr.append($coverTd).append($detailsTd);
            $table.append($tr);
        });

        $('#resultArea').html($table);

        // per-row review/summary population
        $table.find('tr').each(function(idx){
            try {
                var $row = $(this);
                var rIsbn = $row.attr('data-isbn') || '';
                var rIsbn13 = $row.attr('data-isbn13') || '';
                var $ratingEl = $row.find('.summary-rating-val');
                var $rvwCntEl = $row.find('.summary-rvw-cnt');
                var $readCntEl = $row.find('.summary-read-cnt');
                if ((rIsbn && rIsbn.toString().trim().length>0) || (rIsbn13 && rIsbn13.toString().trim().length>0)) {
                    var payload = { isbn: (rIsbn && rIsbn.toString().trim())? rIsbn.toString().trim(): '', isbn13: (rIsbn13 && rIsbn13.toString().trim().length>0)? rIsbn13.toString().trim(): '' };
                    $.ajax({
                        url: contextPath + '/review/summary',
                        type: 'POST',
                        contentType: 'application/json; charset=UTF-8',
                        data: JSON.stringify(payload),
                        success: function(resp) {
                            try {
                                if (resp && resp.status === 'OK' && resp.data) {
                                    var s = resp.data;
                                    var avg = (s.avgRating != null && s.avgRating !== '') ? Number(s.avgRating).toFixed(1) : '-';
                                    var rc = (s.likeCount != null) ? s.likeCount : 0;
                                    var read = (s.readCount != null) ? s.readCount : 0;
                                    if ($ratingEl && $ratingEl.length) $ratingEl.text(avg);
                                    if ($rvwCntEl && $rvwCntEl.length) $rvwCntEl.text(rc);
                                    if ($readCntEl && $readCntEl.length) $readCntEl.text(read);

                                    // Also synchronize per-row wish state from server so UI reflects DB (not only localStorage)
                                    try {
                                        var $wishBtnRow = $row.find('.btn-wish').first();
                                        // compute rawKey similarly to other places (used for localStorage fallback)
                                        var domIsbnRow = $row.attr('data-isbn') || '';
                                        var titleRow = $row.find('.info-title').text() || '';
                                        var authorRow = $row.find('.info-author').text() || '';
                                        var rawKeyRow = (domIsbnRow && domIsbnRow.length) ? domIsbnRow : (titleRow + '|' + authorRow);
                                        // ask server whether current user has wished this item
                                        $.ajax({
                                            url: contextPath + '/wish/count',
                                            type: 'POST',
                                            contentType: 'application/json; charset=UTF-8',
                                            data: JSON.stringify(payload),
                                            success: function(wresp) {
                                                try {
                                                    if (wresp && wresp.status === 'OK') {
                                                        var userHas = false;
                                                        if (typeof wresp.userHasWish !== 'undefined') userHas = !!wresp.userHasWish;
                                                        else if (wresp.data && typeof wresp.data.count !== 'undefined') userHas = Number(wresp.data.count) > 0;

                                                        if ($wishBtnRow && $wishBtnRow.length) {
                                                            if (userHas) {
                                                                $wishBtnRow.addClass('active').attr('aria-pressed','true');
                                                                try { localStorage.setItem(makeStorageKey('mn_wish', rawKeyRow), '1'); } catch(e) {}
                                                            } else {
                                                                $wishBtnRow.removeClass('active').attr('aria-pressed','false');
                                                                try { localStorage.removeItem(makeStorageKey('mn_wish', rawKeyRow)); } catch(e) {}
                                                            }
                                                        }
                                                    }
                                                } catch (e) { console.error('wish count handler error', e); }
                                            },
                                            error: function() { /* ignore wish sync failures */ }
                                        });
                                    } catch (e) { console.warn('wish sync error', e); }
                                }
                            } catch (e) { console.error('summary populate error', e); }
                        },
                        error: function(xhr) { /* ignore per-row summary failures */ }
                    });
                }
            } catch(e) { console.error('per-row summary loop error', e); }
        });
    }

    // Render TMDB movie search results (simple card layout)
    function renderMovieResults(tmdbResp) {
        try {
            if (!tmdbResp) { $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>검색 결과가 없습니다.</p>"); return; }
            // TMDB returns { page, results: [ ... ], total_results, total_pages }
            var results = tmdbResp.results || [];
            if (!Array.isArray(results) || results.length === 0) { $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>검색 결과가 없습니다.</p>"); return; }

            var $table = $("<table class='result-table'></table>");
            results.forEach(function(movie){
                try {
                    var $tr = $("<tr></tr>");
                    $tr.attr('data-movie-id', movie.id || '');

                    var $coverTd = $("<td class='info-cover'></td>");
                    var posterPath = movie.poster_path ? ('https://image.tmdb.org/t/p/w185' + movie.poster_path) : '';
                    var detailHref = movie.id ? ('https://www.themoviedb.org/movie/' + movie.id) : '#';
                    var $a = $("<a class='mn-item-link' target='_blank' rel='noopener'></a>").attr('href', detailHref);
                    var $img = $("<img/>").attr('src', posterPath).attr('alt', movie.title || movie.name || 'poster');
                    $a.append($img); $coverTd.append($a);

                    var $detailsTd = $("<td class='info-details'></td>");
                    var $titleLink = $("<a class='mn-item-link' target='_blank' rel='noopener'></a>").attr('href', detailHref);
                    $titleLink.append($("<div class='info-title'></div>").text(movie.title || movie.name || '제목 없음'));
                    $detailsTd.append($titleLink);

                    var $meta = $("<div class='info-meta'></div>");
                    $meta.append($("<div class='info-author'></div>").text((movie.release_date ? movie.release_date : '') ));
                    $meta.append($("<div class='info-publisher-date'></div>").text(movie.original_language ? (movie.original_language.toUpperCase()) : ''));
                    $detailsTd.append($meta);

                    var $actions = $("<div class='info-actions'></div>");
                    // overview removed from movie list per request
                    // (keep no extra action content for TMDB search results)
                    $detailsTd.append($actions);

                    $tr.append($coverTd).append($detailsTd);
                    $table.append($tr);
                } catch(e) { console.error('renderMovieResults row error', e); }
            });

            $('#resultArea').html($table);
        } catch (e) { console.error('renderMovieResults error', e); $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>결과를 표시할 수 없습니다.</p>"); }
    }

    // performSearch: query the server-side search endpoint and render results
    function performSearch() {
        try {
            var q = ($query.val() || '').toString().trim();
            var mt = ($mediaType.val() || '').toString();
            if (!q || q.length === 0) { alert('검색어를 입력해주세요.'); return; }
            // persist search state for navigation/login flows
            try { saveSearchState(); } catch(e) {}

            // show loading UI
            $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>로딩 중...</p>");

            // If searching for movies, call the server TMDB proxy endpoint
            if (mt === 'movie') {
                $.ajax({
                    url: contextPath + '/movie/search',
                    type: 'GET',
                    data: { query: q },
                    dataType: 'json',
                    success: function(response) {
                        try {
                            // If server returned an error-like shape
                            if (response && response.status === 'ERR') {
                                $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>영화 검색을 처리할 수 없습니다: " + (response.message||'') + "</p>");
                                return;
                            }
                            renderMovieResults(response);
                        } catch (e) { console.error('movie search render error', e); $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>영화 결과를 처리할 수 없습니다.</p>"); }
                    },
                    error: function(xhr) {
                        console.error('영화 검색 호출 실패', xhr && xhr.status);
                        $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>영화 검색 중 오류가 발생했습니다.</p>");
                    }
                });
                return;
            }

            $.ajax({
                url: contextPath + '/hello',
                type: 'GET',
                data: { mediaType: mt, query: q, target: 'title' },
                success: function(response) {
                    try {
                        var items = (typeof response === 'object') ? response : JSON.parse(response);
                        renderSearchResults(items);
                    } catch (e) {
                        console.error('search render error', e);
                        $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>검색 결과를 처리할 수 없습니다.</p>");
                    }
                },
                error: function(xhr) {
                    console.error('검색 호출 실패', xhr && xhr.status);
                    $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>검색 중 오류가 발생했습니다.</p>");
                }
            });
        } catch (e) { console.error('performSearch error', e); }
    }

    // Bind search form submit (Enter key) to performSearch
    $searchForm.on('submit', function(e){ e.preventDefault(); performSearch(); });

    // When a user clicks any result link, save search state before navigating
    $(document).on('click', '#resultArea .mn-item-link', function() {
        saveSearchState();
        // allow navigation to proceed normally
    });

    // Also save on mousedown/auxclick to catch middle-click or open-in-new-tab flows
    $(document).on('mousedown', '#resultArea .mn-item-link', function(e) {
        try { saveSearchState(); } catch (err) {}
        // do not prevent default; just ensure state is saved before navigation
    });
    $(document).on('auxclick', '#resultArea .mn-item-link', function(e) {
        try { saveSearchState(); } catch (err) {}
    });

    // Ensure bestsellers are fetched on initial ready if nothing rendered yet.
    // Some browsers (Chrome) can have different event ordering or preserved state so pageshow
    // logic may not trigger fetchBestsellers; this fallback ensures the user sees content on first load.
    (function ensureInitialBestsellers() {
        try {
            setTimeout(function() {
                try {
                    var $res = $('#resultArea');
                    var isEmpty = !$res || $res.children().length === 0 || ($res.text() || '').trim().length === 0;
                    if (isEmpty && !initialBestsellerLoaded) {
                        try { console.debug('[ensureInitialBestsellers] resultArea empty; fetching bestsellers'); } catch(e){}
                        fetchBestsellers();
                        initialBestsellerLoaded = true;
                    }
                } catch (e) { console.warn('ensureInitialBestsellers check failed', e); }
            }, 120);
        } catch (e) { /* ignore */ }
    })();

    // Immediate fallback: check synchronously right after DOM ready in case setTimeout was skipped
    try {
        try {
            var $resNow = $('#resultArea');
            var nowEmpty = !$resNow || $resNow.children().length === 0 || ($resNow.text() || '').trim().length === 0;
            if (nowEmpty && !initialBestsellerLoaded) {
                try { console.debug('[immediateFallback] resultArea empty; fetching bestsellers'); } catch(e){}
                fetchBestsellers();
                initialBestsellerLoaded = true;
            }
        } catch (e) { console.warn('immediateFallback check failed', e); }
    } catch (e) {}

    // Load-time fallback: if earlier events didn't fetch, try again on window.load (covers image/font blocking scenarios)
    try {
        window.addEventListener('load', function() {
            try {
                var $resLoad = $('#resultArea');
                var loadEmpty = !$resLoad || $resLoad.children().length === 0 || ($resLoad.text() || '').trim().length === 0;
                if (loadEmpty && !initialBestsellerLoaded) {
                    try { console.debug('[loadFallback] resultArea empty on load; fetching bestsellers'); } catch(e){}
                    fetchBestsellers();
                    initialBestsellerLoaded = true;
                }
            } catch (e) { console.warn('loadFallback check failed', e); }
        });
    } catch (e) {}

    // makeStorageKey available globally in this ready scope (used by multiple callbacks)
    function makeStorageKey(prefix, rawKey) {
        try {
            return prefix + ':' + btoa(unescape(encodeURIComponent(rawKey)));
        } catch (e) {
            return prefix + ':' + rawKey;
        }
    }

    // Centralized auth gate helper reused by all action handlers (moved out so both renderers use it)
    function requireLoginThen(action, pending) {
        $.get(contextPath + '/auth/check', function(resp) {
            if (resp === 'OK') {
                action && action();
            } else {
                try {
                    if (pending) {
                        try { pending.returnUrl = location.pathname + (location.search || ''); } catch(e) {}
                        localStorage.setItem('mn_pending_action', JSON.stringify(pending));
                    }
                    try {
                        var _searchState = { mediaType: $mediaType.val(), query: $query.val() };
                        localStorage.setItem('mn_search_state', JSON.stringify(_searchState));
                    } catch (e) { /* ignore storage errors */ }
                } catch (e) { }
                try {
                    var loginHref = contextPath + '/login/kakao';
                    try { loginHref += '?returnUrl=' + encodeURIComponent(location.pathname + (location.search || '')); } catch(e) {}
                    window.location.href = loginHref;
                } catch(e) { window.location.href = contextPath + '/login/kakao'; }
            }
        });
    }

    // Delegated event handlers so dynamically-rendered rows (bestseller + search) behave the same
    // Handle review/like button (💬)
    $(document).on('click', '#resultArea .btn-rvw', function(e){
        e.preventDefault();
        var $btn = $(this);
        // build a compact pending item from DOM values so identifiers are preserved across redirect
        var $row = $btn.closest('tr');
        var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
        var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
        var titleText = $row.find('.info-title').text() || '';
        var authorText = $row.find('.info-author').text() || '';
        var item = {
            isbn: domIsbn || '',
            isbn13: domIsbn13 || '',
            title: titleText.trim(),
            author: authorText.trim(),
            rawKey: (domIsbn && domIsbn.length) ? domIsbn : (titleText ? (titleText + '|' + authorText) : '')
        };

        var pendingItem = { isbn: item.isbn || '', isbn13: item.isbn13 || '', title: item.title || '', author: item.author || '', rawKey: item.rawKey };

        requireLoginThen(function() {
            if (!$btn.hasClass('active')) {
                openReviewModal(item, $btn);
            } else {
                // fetch current review status and open edit modal
                try {
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
                                console.debug('[review/status] response for pendingItem:', pendingItem, resp);
                                var statusObj = null;
                                if (resp && resp.status === 'OK' && resp.data) {
                                    try { statusObj = findStatusForItem(resp.data, pendingItem); } catch(e){ statusObj = null; }
                                }
                                openEditReviewModal(pendingItem, $btn, statusObj);
                            } catch (e) { console.error('Failed to fetch review for edit', e); openEditReviewModal(pendingItem, $btn, null); }
                        },
                        error: function() { openEditReviewModal(pendingItem, $btn, null); }
                    });
                } catch (e) { openEditReviewModal(pendingItem, $btn, null); }
            }
        }, { type: 'like', item: pendingItem });
    });

    // Handle read toggle (📖)
    $(document).on('click', '#resultArea .btn-read', function(e){
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
                            alert('이미 평점이나 리뷰가 등록되어 있어 읽음 표시를 취소할 수 없습니다. 먼저 리뷰를 삭제하거나 평점을 제거하세요.');
                        } else {
                            console.error('Failed to set read status', resp);
                            alert('읽음 상태 변경에 실패했습니다. 다시 시도해주세요.');
                        }
                    } catch (e) { console.error('read success handler error', e); alert('읽음 상태 변경 중 오류가 발생했습니다.'); }
                },
                error: function(xhr) { console.error('Read status AJAX error', xhr.status); alert('읽음 상태를 서버에 저장하지 못했습니다. 다시 시도해주세요.');
                }
            });
        });
    });

    // Handle wishlist toggle (💖)
    $(document).on('click', '#resultArea .btn-wish', function(e){
        e.preventDefault();
        var $btn = $(this);
        var $row = $btn.closest('tr');
        var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
        var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
        var title = $row.find('.info-title').text() || '';
        var author = $row.find('.info-author').text() || '';
        var rawKey = (domIsbn && domIsbn.length) ? domIsbn : (title + '|' + author);
        var pendingItem = { isbn: domIsbn || '', isbn13: domIsbn13 || '', title: title || '', author: author || '', rawKey: rawKey };

        requireLoginThen(function() {
            if (!$btn.hasClass('active')) {
                var payload = { isbn: pendingItem.isbn, isbn13: pendingItem.isbn13 };
                $.ajax({
                    url: contextPath + '/wish/add',
                    type: 'POST',
                    contentType: 'application/json; charset=UTF-8',
                    data: JSON.stringify(payload),
                    success: function(resp) {
                        try {
                            if (resp && resp.status === 'OK') {
                                $btn.addClass('active').attr('aria-pressed','true');
                                try { localStorage.setItem(makeStorageKey('mn_wish', rawKey), '1'); } catch(e){}
                            } else {
                                alert('위시리스트에 추가에 실패했습니다. 다시 시도해주세요.');
                            }
                        } catch (e) { console.error('wish add success handler error', e); alert('오류가 발생했습니다.'); }
                    },
                    error: function(xhr) { console.error('wish add AJAX error', xhr.status); alert('서버에 위시리스트 추가를 요청하지 못했습니다.'); }
                });
            } else {
                var payload = { isbn: pendingItem.isbn, isbn13: pendingItem.isbn13 };
                $.ajax({
                    url: contextPath + '/wish/remove',
                    type: 'POST',
                    contentType: 'application/json; charset=UTF-8',
                    data: JSON.stringify(payload),
                    success: function(resp) {
                        try {
                            if (resp && resp.status === 'OK') {
                                $btn.removeClass('active').attr('aria-pressed','false');
                                try { localStorage.removeItem(makeStorageKey('mn_wish', rawKey)); } catch(e){}
                            } else {
                                alert('위시리스트 제거에 실패했습니다. 다시 시도해주세요.');
                            }
                        } catch (e) { console.error('wish remove success handler error', e); alert('오류가 발생했습니다.'); }
                    },
                    error: function(xhr) { console.error('wish remove AJAX error', xhr.status); alert('서버에 위시리스트 제거를 요청하지 못했습니다.'); }
                });
            }
        }, { type: 'wish', item: pendingItem });
    });

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

    function openEditReviewModal(itemObj, $btnRef, status) {
        try {
            console.debug('[openEditReviewModal] itemObj:', itemObj, 'status:', status);
            // If restoring an existing review, pre-fill the modal fields and show the delete button
            try {
                // Normalize possible field names returned by different endpoints/mappers
                var _rating = null;
                var _cmnt = null;
                var _reviewText = null;
                if (status) {
                    // common names
                    _rating = (typeof status.rating !== 'undefined') ? status.rating : (typeof status.RATING !== 'undefined' ? status.RATING : null);
                    _cmnt = (typeof status.cmnt !== 'undefined') ? status.cmnt : (typeof status.CMNT !== 'undefined' ? status.CMNT : (typeof status.comment !== 'undefined' ? status.comment : null));
                    _reviewText = (typeof status.reviewText !== 'undefined') ? status.reviewText : (typeof status.REVIEW_TEXT !== 'undefined' ? status.REVIEW_TEXT : (typeof status.text !== 'undefined' ? status.text : null));
                    // sometimes nested objects or stringified JSON may occur; attempt to coerce
                    try { if (_rating && typeof _rating === 'object' && _rating.value) _rating = _rating.value; } catch(e){}
                    try { if (_cmnt && typeof _cmnt === 'object' && _cmnt.value) _cmnt = _cmnt.value; } catch(e){}
                    try { if (_reviewText && typeof _reviewText === 'object' && _reviewText.value) _reviewText = _reviewText.value; } catch(e){}
                }

                if (status && (_rating != null || _cmnt != null || _reviewText != null)) {
                    // set rating (ensure option present)
                    var rv = (_rating != null && _rating !== '') ? String(_rating) : '';
                    if (rv) {
                        var $sel = $('#rvw_rating');
                        if ($sel.find('option[value="' + rv + '"]').length === 0) {
                            // add a temporary option if server sent a value like '4.2'
                            $sel.find('.temp-rv-option').remove();
                            $sel.append($('<option>').val(rv).text(rv).addClass('temp-rv-option'));
                        }
                        $sel.val(rv);
                        $sel.trigger('change');
                    } else {
                        $('#rvw_rating').val(''); renderStars('');
                    }
                    $('#rvw_comnet').val(_cmnt != null ? String(_cmnt) : '');
                    $('#rvw_text').val(_reviewText != null ? String(_reviewText) : '');
                    $('#rvw_delete').show();
                } else {
                    // No existing review: hide delete button and clear fields
                    $('#rvw_delete').hide();
                    $('#rvw_comnet').val('');
                    $('#rvw_text').val('');
                    $('#rvw_rating').val(''); renderStars('');
                }
            } catch (e) { console.error('review field restore error', e); $('#rvw_delete').hide(); }
            // Ensure the item identifiers are set for review actions
            currentReviewItem = itemObj;
            var itemIsbn = (itemObj.isbn13 && itemObj.isbn13.length === 13) ? itemObj.isbn13 : '';
            var itemIsbn10 = (itemObj.isbn && itemObj.isbn.length === 10) ? itemObj.isbn : '';
            $('#rvw_item_isbn').val(itemIsbn);
            $('#rvw_item_isbn10').val(itemIsbn10);
            $('#rvw_item_title').val(itemObj.title || '');
            $('#rvw_item_author').val(itemObj.author || '');
            // open the modal with a slight delay to ensure animations are smooth
            setTimeout(function() {
                $('#reviewModal').css('display','flex').hide().fadeIn(200);
            }, 50);
        } catch (e) { console.error('openEditReviewModal error', e); openReviewModal(itemObj, $btnRef); }
    }

    // expose modal helpers globally so callbacks defined elsewhere can call them
    try { window.openEditReviewModal = openEditReviewModal; window.openReviewModal = openReviewModal; } catch(e) {}

    function closeReviewModal() {
        $('#reviewModal').fadeOut(200, function(){ $(this).css('display','none'); try { $('#rvw_rating').find('.temp-rv-option').remove(); } catch(e){} currentReviewItem = null; currentLikeButton = null; });
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
                        try {
                            if (currentLikeButton && currentLikeButton.length) {
                                currentLikeButton.removeClass('active').attr('aria-pressed','false');
                                // clear read button in the same row if present
                                try { currentLikeButton.closest('tr').find('.btn-read').removeClass('active').attr('aria-pressed','false'); } catch(e){}
                            } else {
                                // fallback: try to locate row by ISBN/ISBN13 or title and clear buttons
                                try {
                                    if (currentReviewItem && currentReviewItem.isbn && currentReviewItem.isbn.length) {
                                        var $r = $("tr[data-isbn='" + currentReviewItem.isbn + "']");
                                        if ($r && $r.length) { $r.find('.btn-rvw').removeClass('active').attr('aria-pressed','false'); $r.find('.btn-read').removeClass('active').attr('aria-pressed','false'); }
                                    } else if (currentReviewItem && currentReviewItem.isbn13 && currentReviewItem.isbn13.length) {
                                        var $r2 = $("tr[data-isbn13='" + currentReviewItem.isbn13 + "']");
                                        if ($r2 && $r2.length) { $r2.find('.btn-rvw').removeClass('active').attr('aria-pressed','false'); $r2.find('.btn-read').removeClass('active').attr('aria-pressed','false'); }
                                    } else if (currentReviewItem && currentReviewItem.title) {
                                        $('#resultArea .result-table tr').each(function(){
                                            var $rr = $(this);
                                            var t = $rr.find('.info-title').text().trim();
                                            if (t === (currentReviewItem.title || '').trim()) {
                                                $rr.find('.btn-rvw').removeClass('active').attr('aria-pressed','false');
                                                $rr.find('.btn-read').removeClass('active').attr('aria-pressed','false');
                                            }
                                        });
                                    }
                                } catch (e) {}
                            }
                        } catch(e) {}
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
                    // Run the search to restore results immediately (this covers coming back via browser Back)
                    try { performSearch(); restoredSearchDone = true; } catch (e) { console.error('failed to restore saved search immediately', e); }
                    // remove saved search state after restoring so we don't re-run on subsequent loads
                    try { localStorage.removeItem('mn_search_state'); } catch(e){}
                }
            } catch (e) { console.error('Failed to parse saved search state', e); }
        }

        // 2) Restore any pending action saved before redirecting to login
        var pendingRaw = localStorage.getItem('mn_pending_action');
        var pending = null;
        if (pendingRaw) {
            try {
                pending = JSON.parse(pendingRaw);
            } catch (e) {
                // malformed - remove and ignore
                localStorage.removeItem('mn_pending_action');
                pending = null;
            }
        }

        // If pending action includes a returnUrl and it's not this page, navigate there and let that page handle the pending action
        try {
            if (pending && pending.returnUrl) {
                var currentPath = location.pathname + (location.search || '');
                if (pending.returnUrl !== currentPath) {
                    // leave the pending action in storage so the target page can read it
                    // perform a full redirect to the returnUrl
                    window.location.href = pending.returnUrl;
                    // stop further processing on this page
                    return;
                }
            }
        } catch (e) { console.error('pending redirect check failed', e); }

        // If we didn't redirect away, remove the pending action now to avoid double-processing
        if (!pendingRaw) {
            // no-op
        } else {
            try { localStorage.removeItem('mn_pending_action'); } catch(e){}
        }

        if (pendingRaw) {
            // Remove it immediately to avoid double-processing (already removed above when appropriate)
            //localStorage.removeItem('mn_pending_action');
            //var pending = JSON.parse(pendingRaw);
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
                                // If we already restored earlier on page load, skip here
                                if (!restoredSearchDone) {
                                    try { if (sObj.mediaType) $mediaType.val(sObj.mediaType); } catch(e){}
                                    try { if (sObj.query) $query.val(sObj.query); } catch(e){}
                                    // run search to repopulate results
                                    performSearch();
                                }
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
                                            try { statusObj = findStatusForItem(resp.data, pItem); } catch(e){ statusObj = null; }
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
                // Only show this when we actually restored a pending action (i.e. user was redirected back from login)
                try { if (typeof pending !== 'undefined' && pending) { alert('로그인에 성공했습니다!'); } } catch(e){}
            } else {
                // not logged in; nothing to restore right now
            }
        });
         
    } catch (e) { console.error('Error processing pending action', e); }
});
</script>
</body>
</html>
