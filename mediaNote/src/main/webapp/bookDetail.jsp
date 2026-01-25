<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="com.mn.cm.model.AladinBook"%>
<%
AladinBook b = (AladinBook) request.getAttribute("book");
String message = (String) request.getAttribute("message");
// JS-escaped copies for safe inline insertion into single-quoted JS strings
String jsTitle = "";
String jsAuthor = "";
if (b != null) {
	if (b.getTitle() != null)
		jsTitle = b.getTitle().replace("\\", "\\\\").replace("'", "\\'").replace("\r", "\\r").replace("\n", "\\n")
		.replace("</script>", "<" + "\\/" + "script>");
	if (b.getAuthor() != null)
		jsAuthor = b.getAuthor().replace("\\", "\\\\").replace("'", "\\'").replace("\r", "\\r").replace("\n", "\\n")
		.replace("</script>", "<" + "\\/" + "script>");
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>도서 상세</title>
<link rel="stylesheet"
	href="${pageContext.request.contextPath}/css/style.css">
<style>
.book-detail {
	margin-top: 12px;
}

.book-detail img {
	border-radius: 4px;
}

.summary-badge {
	display: inline-block;
	margin-left: 8px;
	color: #555;
	font-size: 13px;
}

.summary-badge .big {
	font-weight: 700;
	color: #222;
	margin-right: 6px;
}
</style>
</head>
<body>
	<div class="container detail-view" style="position: relative;">
		<%-- include common header partial (user badge + logo) --%>
		<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />
		<a href="#" id="backToList" class="back-to-list"
			aria-label="검색으로 돌아가기">← 돌아가기</a>
		<hr />
		<script>
        (function(){
            var ctx = '<%=request.getContextPath()%>';
            var btn = document.getElementById('backToList');
            if (!btn) return;
            btn.addEventListener('click', function(e){
                e.preventDefault();
                // Save minimal search state (mediaType + query) so index.jsp can restore the original search
                try {
                    // Do not overwrite an existing saved search state (so original user query is preserved).
                    var existing = localStorage.getItem('mn_search_state');
                    if (!existing) {
                        var ss = { mediaType: 'book', query: '<%=jsTitle%>' };
                        localStorage.setItem('mn_search_state', JSON.stringify(ss));
                    }
                } catch (ex) { /* ignore storage errors */ }

                // Prefer using browser history so the previous page (index.jsp) can be restored from bfcache
                // and our pageshow/localStorage restore logic will repopulate the query and results.
                try {
                    if (window.history && window.history.length > 1) {
                        history.back();
                        return;
                    }
                } catch (ex) { console.warn('history.back failed, falling back to index.jsp', ex); }
                // Fallback: navigate directly to the index page
                try { window.location.href = ctx + '/index.jsp'; } catch(e) { /* last resort no-op */ }
            });
        })();
    </script>
		<%
		if (b != null) {
		%>
		<!-- New layout: cover takes full width, info stacked under the image -->
		<div class="book-detail">
			<div class="book-cover"
				style="width: 100%; text-align: center; padding: 10px;">
				<img
					src="<%=b.getCover() != null ? b.getCover() : (request.getContextPath() + "/css/placeholder-cover.png")%>"
					alt="cover"
					style="width: 100%; max-width: 320px; height: auto; display: block; margin: 0 auto; border-radius: 8px;">
			</div>
			<div style="margin: 6px 6px 0 0px; text-align: right;">
				<span id="summary_rating" class="summary-badge" title="평균 평점">
					<span>평점 : </span> <span class="big" id="summary_rating_val">5.0</span>
				</span>
				<button id="detail_rvw_btn" class="btn btn-rvw" type="button"
					aria-pressed="false" title="감상평" aria-label="감상평">💬</button>
				<span id="summary_rvw_cnt">0</span>
				<button id="detail_read_btn" class="btn btn-read" type="button"
					aria-pressed="false" title="읽음" aria-label="읽음">📖</button>
				<span id="summary_read_cnt">0</span>
				<!-- wishlist button placed to the right of detail_read_btn -->
				<button id="detail_wish_btn" class="btn btn-wish" type="button" aria-pressed="false" title="위시리스트" aria-label="위시리스트">💖</button>
				<span id="summary_wish_cnt">0</span>
			</div>
			<div class="book-info" style="margin-top: 0px;">
				<h1 style="margin: 0 0 8px 0; font-size: 22px;"><%=b.getTitle()%></h1>
				<p
					style="color: #555; margin: 0 0 12px 4px; font-size: 14px; padding: 0 0 60px 0px;">
					<strong><%=b.getAuthor()%></strong>
					<%
					if (b.getPublisher() != null && b.getPublisher().trim().length() > 0) {
					%>
					<br>
					<%=b.getPublisher()%>
					<%
					}
					%>
					<%
					if (b.getPubDate() != null && b.getPubDate().trim().length() > 0) {
					%>
					<br>
					<%=b.getPubDate()%>
					<%
					}
					%>
				</p>
				<h2 style="margin: 0 0 10px 0; font-size: 18px;">책 소개</h2>
				<div class="book-desc"
					style="color: #333; line-height: 1.6; margin: 8px 0px 50px 0px;">
					<%=b.getDescription() != null ? b.getDescription() : "(설명 정보가 없습니다)"%>
				</div>
			</div>

			<!-- Reviews summary section -->
			<div id="bookReviews" style="margin-top: 20px;">
				<h2 style="margin: 0 0 10px 0; font-size: 18px;">한줄평 & 감상평</h2>
				<div id="reviewList"
					style="border-top: 1px solid #eee; padding-top: 12px;">
					<p id="noReviews" style="color: #777;">로딩 중...</p>
				</div>
			</div>
		</div>
		<%
		} else {
		%>
		<p>도서를 찾을 수 없습니다.</p>
		<%
		if (message != null) {
		%>
		<p><%=message%></p>
		<%
		}
		%>
		<%
		}
		%>
	</div>

	<!-- Review modal (modern design) (copied from index.jsp) -->
	<div id="reviewModal" class="mn-modal-overlay" aria-hidden="true">
		<div class="mn-modal" role="dialog" aria-modal="true"
			aria-labelledby="mn-modal-title">
			<header class="mn-modal-header">
				<h3 id="mn-modal-title">리뷰 작성</h3>
				<button class="mn-modal-close" aria-label="닫기"
					onclick="closeReviewModal()">✕</button>
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
					<div class="rating-guide-container" style="width: 100%;">
						<strong class="rating-title">⭐ 평점 가이드</strong>
						<ul class="rating-list">
							<li class="rating-item"><span class="rating-score">5.0</span><span
								class="rating-desc">인생 책 (삶에 영향을 준 최고의 책)</span></li>
							<li class="rating-item"><span class="rating-score">4.0
									~ 4.5</span><span class="rating-desc">추천 (재미있고 남들에게 권하고 싶은 책)</span></li>
							<li class="rating-item"><span class="rating-score">3.0
									~ 3.5</span><span class="rating-desc">무난 (읽을만하고 시간이 아깝지 않은 수준)</span></li>
							<li class="rating-item"><span class="rating-score">2.0
									~ 2.5</span><span class="rating-desc">아쉬움 (기대에 못 미치거나 지루함)</span></li>
							<li class="rating-item"><span class="rating-score">1.0</span><span
								class="rating-desc">시간 아까움 (내용이 부실하거나 권하고 싶지 않음)</span></li>
						</ul>
					</div>
				</div>
				<div class="mn-row">
					<label class="mn-label" for="rvw_comnet">한 줄 평</label> <input
						id="rvw_comnet" placeholder="한 줄 평 (생략 가능)" maxlength="200"
						class="mn-input">
				</div>
				<div class="mn-row">
					<label class="mn-label" for="rvw_text">감 상 평</label>
					<textarea id="rvw_text" placeholder="감상평을 입력하세요 (생략 가능)"
						maxlength="2000" class="mn-textarea"></textarea>
				</div>
			</section>
			<footer class="mn-modal-footer">
				<button id="rvw_cancel" class="mn-btn mn-btn-secondary"
					type="button">취소</button>
				<button id="rvw_delete" class="mn-btn mn-btn-danger" type="button"
					style="margin-right: 6px; display: none;">삭제</button>
				<button id="rvw_save" class="mn-btn mn-btn-primary" type="button">저장</button>
			</footer>
		</div>
	</div>

	<!-- load jQuery (needed by modal handlers) -->
	<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
	<script>
    // ensure we have a contextPath variable like index.jsp
    const contextPath = '<%=request.getContextPath()%>';

    // makeStorageKey helper (same behavior as index.jsp)
    function makeStorageKey(prefix, rawKey) {
        try { return prefix + ':' + btoa(unescape(encodeURIComponent(rawKey))); } catch (e) { return prefix + ':' + rawKey; }
    }

    // Review modal handlers copied from index.jsp (adapted)
    var currentReviewItem = null;
    var currentLikeButton = null;
    // cached status for this detail page (populated from server on load)
    var detailStatus = null;

    function openReviewModal(item, $btn) {
        try {
            // If item missing read from btn's row
            if ((!item || Object.keys(item).length === 0) && $btn) {
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
            }

            currentReviewItem = item;
            currentLikeButton = $btn;
            $('#rvw_rating').val('');
            $('#rvw_comnet').val('');
            $('#rvw_text').val('');
            // If we have a cached detailStatus for this page and it matches the item, prefill the modal as edit mode
            try {
                var st = detailStatus;
                var matches = false;
                if (st) {
                    // match by ISBN/ISBN13 if available, else by title
                    if (item && item.isbn && item.isbn.toString().trim().length>0 && st && (st.isbn == item.isbn || String(st.isbn) == String(item.isbn))) matches = true;
                    if (!matches && item && item.isbn13 && item.isbn13.toString().trim().length>0 && st && (st.isbn13 == item.isbn13 || String(st.isbn13) == String(item.isbn13))) matches = true;
                    if (!matches && item && item.title && st && ((st.title && st.title == item.title) || (!st.title && item.title))) matches = matches || false; // best-effort
                }
                if (st && matches) {
                    // prefill rating select (create temp option if needed)
                    var rv = '';
                    if (st.rating != null && String(st.rating).trim() !== '') {
                        try { var num = Number(st.rating); if (!isNaN(num)) rv = num.toFixed(1); else rv = String(st.rating); } catch(e) { rv = String(st.rating); }
                    }
                    try {
                        var $sel = $('#rvw_rating');
                        if (rv && $sel.find('option[value="' + rv + '"]').length === 0) {
                            // try nearest 0.5 candidate
                            var n = Number(rv);
                            if (!isNaN(n)) {
                                var rounded = Math.round(n*2)/2; var candidate = rounded.toFixed(1);
                                if ($sel.find('option[value="' + candidate + '"]').length>0) rv = candidate;
                            }
                        }
                        if (rv && $sel.find('option[value="' + rv + '"]').length === 0) {
                            $sel.find('.temp-rv-option').remove();
                            $sel.append($('<option>').val(rv).text(rv).addClass('temp-rv-option'));
                        }
                        $sel.val(rv);
                        $sel.find('option').prop('selected', false);
                        var $opt = $sel.find('option[value="' + rv + '"]'); if ($opt.length>0) $opt.prop('selected', true);
                        $sel.trigger('change');
                    } catch (e) { console.error('prefill rating error', e); }
                    $('#rvw_comnet').val(st.cmnt != null ? String(st.cmnt) : '');
                    $('#rvw_text').val(st.reviewText != null ? String(st.reviewText) : '');
                    renderStars(rv);
                    try { $('#rvw_delete').show(); } catch(e){}
                } else {
                    try { $('#rvw_delete').hide(); } catch(e){}
                }
            } catch(e) { console.error('openReviewModal prefill check error', e); }
            $('#reviewModal').css('display','flex').hide().fadeIn(200);
         } catch (e) { console.error('openReviewModal error', e); }
     }

    function closeReviewModal() {
        $('#reviewModal').fadeOut(200, function(){
            $(this).css('display','none');
            try { $('#rvw_rating').find('.temp-rv-option').remove(); } catch(e){}
            currentReviewItem = null;
            currentLikeButton = null;
        });
    }

    $('#rvw_cancel').on('click', function() { closeReviewModal(); });

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
                        var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || ''));
                        try { localStorage.removeItem(makeStorageKey('mn_like', rawKey)); } catch(e){}
                        try { localStorage.removeItem(makeStorageKey('mn_read', rawKey)); } catch(e){}
                        // clear UI state: the like button in the row (if exists), plus detail page buttons
                        try {
                            if (currentLikeButton && currentLikeButton.length) {
                                currentLikeButton.removeClass('active').attr('aria-pressed','false');
                                // also try to clear read button in the same row
                                try { currentLikeButton.closest('tr').find('.btn-read').removeClass('active').attr('aria-pressed','false'); } catch(e){}
                            }
                            // clear global detail page buttons too (in case modal opened from detail page)
                            try { $('#detail_rvw_btn').removeClass('active').attr('aria-pressed','false'); } catch(e){}
                            try { $('#detail_read_btn').removeClass('active').attr('aria-pressed','false'); } catch(e){}
                        } catch(e) {}
                        // update cached detail status (deleted)
                        detailStatus = null;
                        alert('리뷰가 삭제되었습니다.');
                        closeReviewModal();
                        // Refresh review list
                        loadReviewList();
                        // Refresh summary
                        loadBookSummary();
                    } else {
                        alert('리뷰 삭제에 실패했습니다. 다시 시도해주세요.');
                    }
                } catch (e) { console.error('delete success handler error', e); alert('리뷰 삭제 중 오류가 발생했습니다.'); }
            },
            error: function(xhr) { console.error('Delete AJAX error', xhr.status); alert('리뷰 삭제 요청을 서버에 전달하지 못했습니다. 다시 시도해주세요.'); }
        });
    });

    $('#rvw_save').on('click', function() {
        const rating = $('#rvw_rating').val();
        const comment = $('#rvw_comnet').val();
        const text = $('#rvw_text').val();

        if (!rating) { alert('평점을 선택해주세요.'); return; }
        if (!currentReviewItem) { alert('리뷰할 항목 정보가 없습니다. 다시 시도해주세요.'); return; }

        const itemIsbn = (currentReviewItem && (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10)) ? (currentReviewItem.isbn || currentReviewItem.isbn13 || currentReviewItem.isbn10) : '';
        const fallbackKey = (!itemIsbn && currentReviewItem) ? ((currentReviewItem.title || '') + '|' + (currentReviewItem.author || '')) : '';
        const reviewData = { itemId: itemIsbn, itemKey: fallbackKey, isbn: currentReviewItem.isbn || '', isbn13: currentReviewItem.isbn13 || '', title: currentReviewItem.title || '', author: currentReviewItem.author || '', rating: rating, comment: comment, text: text };

        if ((!reviewData.itemId || reviewData.itemId.trim() === '') && (!reviewData.itemKey || reviewData.itemKey.trim() === '')) { alert('도서 식별자(ISBN) 또는 항목 정보가 없습니다. 검색에서 해당 항목을 선택한 뒤 다시 시도해주세요.'); return; }

        $.ajax({ url: contextPath + "/review/save", type: "POST", contentType: "application/x-www-form-urlencoded; charset=UTF-8", data: $.param(reviewData), success: function(response) {
             const rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || ''));
             const likeKey = makeStorageKey('mn_like', rawKey);
             const readKey = makeStorageKey('mn_read', rawKey);
             try { localStorage.setItem(likeKey, '1'); } catch(e) {}
             try { localStorage.setItem(readKey, '1'); } catch(e) {}
             // update cached detail status to reflect saved review
             try { detailStatus = detailStatus || {}; detailStatus.rating = reviewData.rating; detailStatus.cmnt = reviewData.comment; detailStatus.reviewText = reviewData.text; detailStatus.readYn = 'Y'; } catch(e) {}
            // Activate detail view buttons (if present) so saved rating immediately reflects in UI
            try {
                try { $('#detail_rvw_btn').addClass('active').attr('aria-pressed','true'); } catch(e){}
                try { $('#detail_read_btn').addClass('active').attr('aria-pressed','true'); } catch(e){}
            } catch(e) {}
+            // Immediately update the big summary rating on detail page
+            try {
+                var savedRating = reviewData.rating || reviewData.rating;
+                var disp = null;
+                try { if (savedRating != null && String(savedRating).trim().length>0 && !isNaN(Number(savedRating))) disp = Number(savedRating).toFixed(1); } catch(e) { disp = null; }
+                if (disp != null) {
+                    try { $('#summary_rating_val').text(disp); } catch(e) { console.error('Failed to set #summary_rating_val', e); }
+                }
+            } catch(e) { console.error('detail rating immediate update error', e); }
             closeReviewModal();
             alert('리뷰가 저장되었습니다.');
             // Refresh review list
             loadReviewList();
             // Refresh summary
             loadBookSummary();
         }, error: function(xhr) { console.error("리뷰 저장 에러:", xhr.status); alert('리뷰 저장 중 오류가 발생했습니다. 나중에 다시 시도해주세요.'); } });
    });

    function renderStars(val, target) { 
        var out='';
        if (!val || String(val).trim()=== '') out='☆☆☆☆☆';
        else { 
            var num = Math.floor(Number(val)); if (isNaN(num)) num = 0;
            for (var i=0;i<num;i++) out += '★';
            for (var j=num;j<5;j++) out += '☆';
        }
        var text = out + (val ? ('  ' + val) : '');
        try {
            if (target) {
                var el = null;
                if (typeof target === 'string') el = document.getElementById(target);
                else el = target;
                if (el) el.textContent = text;
                return;
            }
        } catch(e) { /* ignore */ }
        var el=document.getElementById('starDisplay'); if (el) el.textContent = text;
    }

    (function(){ var sel = document.getElementById('rvw_rating'); if (sel) sel.addEventListener('change', function(){ renderStars(this.value); }); var overlay = document.getElementById('reviewModal'); if (overlay) overlay.addEventListener('click', function(e){ if (e.target === overlay) closeReviewModal(); }); window.closeReviewModal = closeReviewModal; document.addEventListener('keydown', function(e){ if (e.key === 'Escape' || e.key === 'Esc') { var ov = document.getElementById('reviewModal'); if (ov && ov.style.display !== 'none') closeReviewModal(); } }); })();

    // end modal handlers

    // openReviewModal with existing values (for editing)
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
                            rv = num.toFixed(1);
                        } else {
                            rv = String(status.rating);
                        }
                    } catch (e) { rv = String(status.rating); }
                }
                try {
                    var $sel = $('#rvw_rating');
                    if (rv && $sel.find('option[value="' + rv + '"]').length === 0) {
                        var n = Number(rv);
                        if (!isNaN(n)) {
                            var rounded = Math.round(n * 2) / 2;
                            var candidate = rounded.toFixed(1);
                            if ($sel.find('option[value="' + candidate + '"]').length > 0) rv = candidate;
                            else {
                                var floor = (Math.floor(n) + (Math.floor((n - Math.floor(n)) * 2) / 2)).toFixed(1);
                                if ($sel.find('option[value="' + floor + '"]').length > 0) rv = floor;
                            }
                        }
                    }
                    if (rv && $('#rvw_rating').find('option[value="' + rv + '"]').length === 0) {
                        $sel.find('.temp-rv-option').remove();
                        $sel.append($('<option>').val(rv).text(rv).addClass('temp-rv-option'));
                    }
                    $sel.val(rv);
                    $sel.find('option').prop('selected', false);
                    var $opt = $sel.find('option[value="' + rv + '"]');
                    if ($opt.length > 0) $opt.prop('selected', true);
                    $sel.trigger('change');
                } catch (e) { console.error('rating select set error', e); }
                $('#rvw_comnet').val(status.cmnt != null ? String(status.cmnt) : '');
                $('#rvw_text').val(status.reviewText != null ? String(status.reviewText) : '');
                renderStars(rv);
             } else {
                 $('#rvw_rating').val('');
                 $('#rvw_comnet').val('');
                 $('#rvw_text').val('');
                 renderStars('');
             }

             currentReviewItem = itemObj;
             currentLikeButton = $btnRef;
             try { if (status) { $('#rvw_delete').show(); } else { $('#rvw_delete').hide(); } } catch (e) {}
             $('#reviewModal').css('display','flex').hide().fadeIn(200);
        } catch (e) { console.error('openEditReviewModal error', e); openReviewModal(itemObj, $btnRef); }
    }

    // requireLoginThen helper (same behavior as index.jsp)
    function requireLoginThen(action, pending) {
        $.get(contextPath + '/auth/check', function(resp) {
            if (resp === 'OK') {
                action();
            } else {
                try {
                    if (pending) {
                        // ensure the pending contains a returnUrl so the login flow can return to this detail page
                        try { pending.returnUrl = location.pathname + (location.search || ''); } catch(e) {}
                        localStorage.setItem('mn_pending_action', JSON.stringify(pending));
                    }
                    // Save a minimal search state so user returns smoothly after login
                    try { localStorage.setItem('mn_search_state', JSON.stringify({ mediaType: 'book', query: '<%=jsTitle%>' })); } catch (e) {}
                } catch (e) {}
                try {
                    var loginHref = contextPath + '/login/kakao';
                    try { loginHref += '?returnUrl=' + encodeURIComponent(location.pathname + (location.search || '')); } catch(e) {}
                    window.location.href = loginHref;
                } catch(e) {
                    window.location.href = contextPath + '/login/kakao';
                }
            }
        });
    }

    // wire up detail like button to open same review modal as index.jsp
    (function(){
        var $btn = $('#detail_rvw_btn');
        if (!$btn || $btn.length === 0) return;
        $btn.on('click', function(){
            var currentlyActive = $btn.hasClass('active');
            var itemObj = { isbn: '<%=b != null ? b.getIsbn() : ""%>', isbn13: '<%=b != null ? b.getIsbn13() : ""%>', title: '<%=jsTitle%>', author: '<%=jsAuthor%>' };
            // require login, then open modal or edit modal based on whether a review exists in DB (detailStatus)
            requireLoginThen(function(){
                if (detailStatus) {
                    openEditReviewModal(itemObj, null, detailStatus);
                } else {
                    openReviewModal(itemObj, null);
                }
            }, { type: 'like', item: itemObj });
        });
    })();

    // wire up detail read button to reuse /review/read endpoint and update UI/localStorage
    (function(){
        var $rbtn = $('#detail_read_btn');
        if (!$rbtn || $rbtn.length === 0) return;
        $rbtn.on('click', function(){
            var currentlyActive = $rbtn.hasClass('active');
            var desired = currentlyActive ? 'N' : 'Y';
            var itemObj = { isbn: '<%=b != null ? b.getIsbn() : ""%>', isbn13: '<%=b != null ? b.getIsbn13() : ""%>', title: '<%=jsTitle%>', author: '<%=jsAuthor%>' };
            requireLoginThen(function(){
                $.ajax({
                    url: contextPath + '/review/read',
                    type: 'POST',
                    contentType: 'application/json; charset=UTF-8',
                    data: JSON.stringify({ isbn: itemObj.isbn, isbn13: itemObj.isbn13, readYn: desired }),
                    success: function(resp){
                        try {
                            if (resp && resp.status === 'OK') {
                                var rawKey = itemObj.isbn && itemObj.isbn.length ? itemObj.isbn : (itemObj.title + '|' + (itemObj.author || ''));
                                if (desired === 'Y') { $rbtn.addClass('active').attr('aria-pressed','true'); try{ localStorage.setItem(makeStorageKey('mn_read', rawKey),'1'); }catch(e){} }
                                else { $rbtn.removeClass('active').attr('aria-pressed','false'); try { localStorage.removeItem(makeStorageKey('mn_read', rawKey)); } catch(e) {} }
                                // refresh summary counts
                                loadBookSummary();
                                // refresh wish count too
                                loadWishCount();
                            } else if (resp && resp.status === 'ERR' && resp.message === 'CANNOT_UNSET_READ_HAS_RATING') {
                                alert('이미 평점이나 리뷰가 등록되어 있어 읽음 표시를 취소할 수 없습니다. 먼저 리뷰를 삭제하거나 평점을 제거하세요.');
                            } else { alert('읽음 상태 변경에 실패했습니다.'); }
                        } catch (e) { console.error('read toggle error', e); alert('오류가 발생했습니다.'); }
                    }, error: function(){ alert('서버와 통신할 수 없습니다.'); }
                });
            }, { type: 'read', item: itemObj });
        });
    })();

    // Wire up detail wish button: toggle add/remove via /wish endpoints and update count
    (function(){
        var $wbtn = $('#detail_wish_btn');
        if (!$wbtn || $wbtn.length === 0) return;
        function refreshWishCount() { loadWishCount(); }
        $wbtn.on('click', function(){
            var $btn = $(this);
            var currentlyActive = $btn.hasClass('active');
            var itemObj = { isbn: '<%=b != null ? b.getIsbn() : ""%>', isbn13: '<%=b != null ? b.getIsbn13() : ""%>', title: '<%=jsTitle%>', author: '<%=jsAuthor%>' };
            requireLoginThen(function(){
                if (!currentlyActive) {
                    // add
                	$.ajax({
                	    url: contextPath + '/wish/add',
                	    type: 'POST',
                	    contentType: 'application/json; charset=UTF-8',
                	    data: JSON.stringify({
                	        isbn: itemObj.isbn,
                	        isbn13: itemObj.isbn13
                	    }),
                	    success: function(resp) {
                	        // 1. 응답 상태 체크 (문자열일 경우를 대비해 trim() 추가 권장)
                	        if (resp && resp.status === 'OK') {
                	            // 버튼 상태 변경
                	            $btn.addClass('active').attr('aria-pressed', 'true');

                	            try {
                	                // 2. LocalStorage 저장 로직 수정 (괄호 누락 및 키 생성 로직 정리)
                	                const storageKey = (itemObj.isbn && itemObj.isbn.length > 0) 
                	                                   ? itemObj.isbn 
                	                                   : (itemObj.title + '|' + (itemObj.author || ''));
                	                
                	                localStorage.setItem(makeStorageKey('mn_wish', storageKey), '1'); 
                	            } catch (e) {
                	                console.warn('LocalStorage 저장 실패:', e);
                	            }

                	            // 3. 위시리스트 카운트 갱신
                	            if (typeof refreshWishCount === 'function') {
                	                refreshWishCount();
                	            }
                	            
                	            alert('위시리스트에 담겼습니다.');
                	        } else {
                	            // 서버에서 에러 메시지를 보내주는 경우 해당 메시지 출력
                	            alert(resp.message || '위시리스트 추가에 실패했습니다.');
                	        }
                	    },
                	    error: function(xhr, status, error) {
                	        console.error('통신 에러:', error);
                	        alert('서버와 통신할 수 없습니다. 잠시 후 다시 시도해주세요.');
                	    }
                	}); 
               	} else {
                		
                    // remove
               		$.ajax({
               		    url: contextPath + '/wish/remove',
               		    type: 'POST',
               		    contentType: 'application/json; charset=UTF-8',
               		    data: JSON.stringify({
               		        isbn: itemObj.isbn,
               		        isbn13: itemObj.isbn13
               		    }),
               		    success: function(resp) {
               		        if (resp && resp.status === 'OK') {
               		            // 1. UI 상태 변경: active 클래스 제거 및 aria-pressed 해제
               		            $btn.removeClass('active').attr('aria-pressed', 'false');

               		            try {
               		                // 2. LocalStorage에서 해당 아이템 삭제
               		                // 키 생성 로직을 변수화하여 가독성 향상
               		                const itemKey = (itemObj.isbn && itemObj.isbn.length > 0) 
               		                                ? itemObj.isbn 
               		                                : (itemObj.title + '|' + (itemObj.author || ''));
               		                
               		                // 기존 코드에서 누락되었던 괄호를 닫아줌
               		                localStorage.removeItem(makeStorageKey('mn_wish', itemKey)); 
               		            } catch (e) {
               		                console.warn('LocalStorage 삭제 실패:', e);
               		            }

               		            // 3. 카운트 갱신
               		            if (typeof refreshWishCount === 'function') {
               		                refreshWishCount();
               		            }

               		            alert('위시리스트에서 제거되었습니다.');
               		        } else {
               		            alert(resp.message || '위시리스트 제거에 실패했습니다.');
               		        }
               		    },
               		    error: function(xhr, status, error) {
               		        console.error('삭제 요청 에러:', error);
               		        alert('서버와 통신할 수 없습니다.');
               		    }
               		});
                }
            }, { type: 'wish', item: itemObj });
        });
    })();

    // Fetch and show wish count for the book
    function loadWishCount() {
        var isbnVal = '<%=b != null && b.getIsbn() != null ? b.getIsbn() : ""%>';
        var isbn13Val = '<%=b != null && b.getIsbn13() != null ? b.getIsbn13() : ""%>';
        var payload = { isbn: (isbnVal && isbnVal.toString().trim().length>0)?isbnVal:'', isbn13: (isbn13Val && isbn13Val.toString().trim().length>0)?isbn13Val:'' };
        if (!((payload.isbn && payload.isbn.toString().trim().length>0) || (payload.isbn13 && payload.isbn13.toString().trim().length>0))) { $('#summary_wish_cnt').text('0'); return; }
        $.ajax({
            url: contextPath + '/wish/count',
            type: 'POST',
            contentType: 'application/json; charset=UTF-8',
            data: JSON.stringify(payload),
            success: function(resp){
                try {
                    if (resp && resp.status === 'OK') {
                        // update count if provided
                        if (resp.data && typeof resp.data.count !== 'undefined') {
                            $('#summary_wish_cnt').text(resp.data.count);
                        }
                        // sync current user's wish state to button (if server included it)
                        try {
                            var $wishBtn = $('#detail_wish_btn');
                            if ($wishBtn && $wishBtn.length) {
                                var userHas = false;
                                if (typeof resp.userHasWish !== 'undefined') userHas = !!resp.userHasWish;
                                else if (typeof resp.userWishCount !== 'undefined') userHas = Number(resp.userWishCount) > 0;
                                if (userHas) {
                                    $wishBtn.addClass('active').attr('aria-pressed','true');
                                } else {
                                    $wishBtn.removeClass('active').attr('aria-pressed','false');
                                }
                            }
                        } catch (e) { console.warn('wish button sync error', e); }
                    }
                } catch(e){ console.error('wish count handler', e); }
            },
            error: function() { console.error('wish count AJAX error'); }
        });
    }

    // call once initially to populate wish count and button state
    loadWishCount();
    // --- initialize: fetch review/status for this book to show correct modal state ---
    (function(){
        var isbnVal = '<%=b != null && b.getIsbn() != null ? b.getIsbn() : ""%>';
        var isbn13Val = '<%=b != null && b.getIsbn13() != null ? b.getIsbn13() : ""%>';
        var payload = { isbns: [], isbns13: [] };
        if (isbnVal && isbnVal.toString().trim().length>0) payload.isbns.push(isbnVal.toString().trim());
        if (isbn13Val && isbn13Val.toString().trim().length>0) payload.isbns13.push(isbn13Val.toString().trim());
        if ((payload.isbns && payload.isbns.length>0) || (payload.isbns13 && payload.isbns13.length>0)) {
            $.ajax({
                url: contextPath + '/review/status',
                type: 'POST',
                contentType: 'application/json; charset=UTF-8',
                data: JSON.stringify(payload),
                success: function(resp) {
                    try {
                        if (resp && resp.status === 'OK' && resp.data) {
                            var st = null;
                            if (payload.isbns && payload.isbns.length>0 && resp.data[payload.isbns[0]]) st = resp.data[payload.isbns[0]];
                            if (!st && payload.isbns13 && payload.isbns13.length>0 && resp.data[payload.isbns13[0]]) st = resp.data[payload.isbns13[0]];
                            if (!st) {
                                var keys = Object.keys(resp.data || {});
                                if (keys && keys.length>0) st = resp.data[keys[0]];
                            }
                            if (st) {
                                detailStatus = st;
                                var rawKey = (isbnVal && isbnVal.length) ? isbnVal : ('<%=jsTitle%>' + '|' + '<%=jsAuthor%>');
                                if (st.readYn && String(st.readYn) === 'Y') { $('#detail_read_btn').addClass('active').attr('aria-pressed','true'); try{ localStorage.setItem(makeStorageKey('mn_read', rawKey),'1'); }catch(e){} }
                                if ((st.rating != null && String(st.rating).trim() !== '') || (st.cmnt != null && String(st.cmnt).trim() !== '') || (st.reviewText != null && String(st.reviewText).trim() !== '')) { $('#detail_rvw_btn').addClass('active').attr('aria-pressed','true'); try{ localStorage.setItem(makeStorageKey('mn_like', rawKey),'1'); }catch(e){} }
                            }
                        }
                    } catch (e) { console.error('detail status init error', e); }
                }, error: function(){ /* ignore */ }
            });
        }
        // initial load of book-level summary
        loadBookSummary();
    })();

    // After status init, check for a pending action (saved before redirecting to login) and resume if it's for this detail page
    (function(){
        try {
            var pendingRaw = localStorage.getItem('mn_pending_action');
            if (!pendingRaw) return;
            var pending = null;
            try { pending = JSON.parse(pendingRaw); } catch(e) { localStorage.removeItem('mn_pending_action'); return; }
            // If pending.returnUrl exists and doesn't match this page, don't process here
            try {
                var currentPath = location.pathname + (location.search || '');
                if (pending.returnUrl && pending.returnUrl !== currentPath) {
                    // leave it for another page
                    return;
                }
            } catch(e) {}

            // remove it now to avoid duplicate processing
            try { localStorage.removeItem('mn_pending_action'); } catch(e){}

            if (pending && pending.type === 'like' && pending.item) {
                var pItem = pending.item;
                // If this pending item has a movie id, ask status by mvIds; otherwise ask by ISBNs
                try {
                    if (pItem.mvId && String(pItem.mvId).trim().length > 0) {
                        var mvPayload = { mvIds: [ pItem.mvId ] };
                        $.ajax({
                            url: contextPath + '/review/status',
                            type: 'POST',
                            contentType: 'application/json; charset=UTF-8',
                            data: JSON.stringify(mvPayload),
                            success: function(resp) {
                                try {
                                    var statusObj = null;
                                    if (resp && resp.status === 'OK' && resp.data) {
                                        try { statusObj = resp.data[String(pItem.mvId)]; } catch(e) { statusObj = null; }
                                    }
                                    if (statusObj) {
                                        detailStatus = statusObj;
                                        openEditReviewModal(pItem, null, statusObj);
                                    } else { openReviewModal(pItem, null); }
                                } catch(e) { console.error('resume pending movie handler error', e); openReviewModal(pItem, null); }
                            }, error: function() { openReviewModal(pItem, null); }
                        });
                    } else {
                        var payload = { isbns: [], isbns13: [] };
                        if (pItem.isbn && pItem.isbn.toString().trim().length>0) payload.isbns.push(pItem.isbn.toString().trim());
                        if (pItem.isbn13 && pItem.isbn13.toString().trim().length>0) payload.isbns13.push(pItem.isbn13.toString().trim());
                        $.ajax({
                            url: contextPath + '/review/status',
                            type: 'POST',
                            contentType: 'application/json; charset=UTF-8',
                            data: JSON.stringify(payload),
                            success: function(resp) {
                                try {
                                    var statusObj = null;
                                    if (resp && resp.status === 'OK' && resp.data) {
                                        if (payload.isbns && payload.isbns.length>0 && resp.data[payload.isbns[0]]) statusObj = resp.data[payload.isbns[0]];
                                        if (!statusObj && payload.isbns13 && payload.isbns13.length>0 && resp.data[payload.isbns13[0]]) statusObj = resp.data[payload.isbns13[0]];
                                        if (!statusObj) {
                                            var keys = Object.keys(resp.data || {});
                                            if (keys && keys.length>0) statusObj = resp.data[keys[0]];
                                        }
                                    }
                                    if (statusObj) {
                                        detailStatus = statusObj;
                                        openEditReviewModal(pItem, null, statusObj);
                                    } else {
                                        openReviewModal(pItem, null);
                                    }
                                } catch(e) { console.error('resume pending handler error', e); openReviewModal(pItem, null); }
                            }, error: function() { openReviewModal(pItem, null); }
                        });
                    }
                } catch(e) { console.error('resume pending overall error', e); openReviewModal(pItem, null); }
            }
        } catch (e) { console.error('Failed to resume pending action on detail page', e); }
    })();

    // --- reviews section: fetch and display ---
    // loadReviewList: reusable function to fetch and render reviews for this book
    function loadReviewList() {
        var isbnVal = '<%=b != null && b.getIsbn() != null ? b.getIsbn() : ""%>';
        var isbn13Val = '<%=b != null && b.getIsbn13() != null ? b.getIsbn13() : ""%>';
        var payload = { isbn: isbnVal || '', isbn13: isbn13Val || '', limit: 20 };
        var $list = $('#reviewList');
        // Clear only existing review items but keep a placeholder <p id="noReviews"> inside the container
        // Re-create the placeholder so we can reliably update it regardless of prior DOM state
        $list.empty();
        $list.html('<p id="noReviews" style="color: #777; height:100px;">로딩 중...</p>');
        var $noReviews = $list.find('#noReviews');
        $noReviews.show();
        if (!((payload.isbn && payload.isbn.toString().trim().length>0) || (payload.isbn13 && payload.isbn13.toString().trim().length>0))) {
            // fallback text when no identifiers available
            $noReviews.text('감상평이 없습니다.').show();
            return;
        }
        $.ajax({
            url: contextPath + '/review/list',
            type: 'POST',
            contentType: 'application/json; charset=UTF-8',
            data: JSON.stringify(payload),
            success: function(resp) {
                try {
                    // Normalize reviews from various possible server response shapes
                    function normalizeReviews(resp) {
                        if (!resp) return null;
                        // If resp itself is an array
                        if (Array.isArray(resp)) return resp;
                        // If resp.data is an array or wrapper object
                        if (resp.data) {
                            var d = resp.data;
                            if (Array.isArray(d)) return d;
                            if (d.reviews && Array.isArray(d.reviews)) return d.reviews;
                            if (d.list && Array.isArray(d.list)) return d.list;
                            if (d.items && Array.isArray(d.items)) return d.items;
                            if (d.rows && Array.isArray(d.rows)) return d.rows;
                            // If data is an object keyed by ids -> collect values
                            if (typeof d === 'object') {
                                var vals = [];
                                Object.keys(d).forEach(function(k){ if (d[k] && typeof d[k] === 'object') vals.push(d[k]); });
                                if (vals.length > 0) return vals;
                            }
                        }
                        // Some APIs put payload directly under resp.result or resp.payload
                        if (resp.result && Array.isArray(resp.result)) return resp.result;
                        if (resp.payload && Array.isArray(resp.payload)) return resp.payload;
                        return null;
                    }

                    var reviews = normalizeReviews(resp);
                    // Debug: log raw response to help troubleshooting in browser console
                    try { console.debug('[review/list] raw response:', resp); } catch(e) {}
                     // If server returned no recognizable reviews array, show message
                    if (!reviews || !Array.isArray(reviews) || reviews.length === 0) {
                        try { console.debug('[review/list] normalized reviews empty or invalid:', reviews); } catch(e) {}
                        $noReviews.text('감상평이 없습니다.').show();
                        return;
                    }
                    $noReviews.hide();
                    for (var i = 0; i < reviews.length; i++) {
                         var rv = reviews[i];
                         var $item = $('<div>').addClass('review-item').css('margin-bottom', '16px').css('padding-bottom','12px').css('border-bottom','1px solid #f0f0f0');
                         var $header = $('<div>').addClass('review-header').css('margin-bottom', '6px').css('display','flex').css('align-items','center');
                         var ratingVal = (rv.RATING != null) ? rv.RATING : (rv.rating != null ? rv.rating : '');
                         var comnetVal = rv.CMNT || rv.cmnt || rv.comment || '';
                         var reviewVal = rv.REVIEW_TEXT || rv.reviewText || rv.text || '';
                         // Compute masked nickname
                         var rawNick = rv.NICKNAME || rv.nickname || rv.nick || '';
                         var nick = '익명';
                         try {
                             var nTrim = String(rawNick || '').trim();
                             if (nTrim.length === 0) { nick = '익명'; }
                             else if (nTrim.length === 1) { nick = nTrim; }
                             else { nick = nTrim.charAt(0) + '*' + nTrim.charAt(nTrim.length - 1); }
                         } catch (e) { nick = (rawNick && rawNick.length) ? rawNick : '익명'; }
                         var $nickname = $('<span>').addClass('review-nickname').css('font-weight', '700').css('margin-right','8px').text(nick);
                         var $rating = $('<span>').addClass('review-rating').css('color','#f39c12').css('font-size','14px');
                         try { renderStars(ratingVal, $rating[0]); } catch(e) { if (ratingVal) $rating.text(String(ratingVal)); }
                         // like/dislike counts from server (fallback to 0)
                         var lkCnt = Number(rv.LK_CNT != null ? rv.LK_CNT : (rv.lkCnt != null ? rv.lkCnt : 0)) || 0;
                         var dslkCnt = Number(rv.DSLK_CNT != null ? rv.DSLK_CNT : (rv.dslkCnt != null ? rv.dslkCnt : 0)) || 0;
                         // vote controls container, pushed to right via margin-left:auto
                         var $voteWrap = $('<div>').addClass('review-votes').css({ 'margin-left': 'auto', 'display':'flex', 'gap':'8px', 'align-items':'center' });
                         var $likeBtn = $('<button>').addClass('review-like-btn').attr('type','button').css({'background':'transparent', 'border':'none','cursor':'pointer','color':'#2d8cff','font-weight':'700'}).text('👍 ' + lkCnt);
                         var $dislikeBtn = $('<button>').addClass('review-dislike-btn').attr('type','button').css({'background':'transparent', 'border':'none','cursor':'pointer','color':'#999','font-weight':'700'}).text('👎 ' + dslkCnt);
                         // attach handlers that check existing reaction before voting
                         (function($lb, $db, rvData){
                            function doVote(action) {
                                var reg = rvData.REG_DT || rvData.reg_dt || '';
                                if (!reg || String(reg).trim().length === 0) { alert('리뷰 식별정보가 없어 투표할 수 없습니다.'); return; }
                                // first check existing reaction for this user+review
                                $.ajax({
                                    url: contextPath + '/review/reaction',
                                    type: 'POST',
                                    contentType: 'application/json; charset=UTF-8',
                                    data: JSON.stringify({ isbn: isbnVal, isbn13: isbn13Val, regDt: reg }),
                                    success: function(resp) {
                                        try {
                                            if (resp && resp.status === 'OK') {
                                                // server returns numeric reaction: 0 = like, 1 = dislike, or null
                                                var existing = (resp.data && (resp.data.reaction !== null && resp.data.reaction !== undefined)) ? resp.data.reaction : null;
                                                var existingAction = null;
                                                if (existing === 0) existingAction = 'like';
                                                else if (existing === 1) existingAction = 'dislike';
                                                // if the user already performed the same action, inform them and skip
                                                // if (existingAction === action) {
                                                //     if (action === 'like') alert('이미 좋아요를 누르셨습니다.');
                                                //     else alert('이미 싫어요를 누르셨습니다.');
                                                //     return;
                                                // }
                                                // If user already performed same action, allow server to toggle it off by proceeding.
                                                // Do not early-return here; the server will detect same-action and delete the reaction.
                                                // (This enables clicking same-action to remove the like/dislike.)
                                                // if (existingAction === action) { /* proceed to toggle off on server */ }

                                                // proceed to vote (will insert/update MN_BK_LIKE)
                                                $.ajax({
                                                    url: contextPath + '/review/vote',
                                                    type: 'POST',
                                                    contentType: 'application/json; charset=UTF-8',
                                                    data: JSON.stringify({ isbn: isbnVal, isbn13: isbn13Val, regDt: reg, action: action }),
                                                    success: function(vresp) {
                                                        try {
                                                            if (vresp && vresp.status === 'OK' && vresp.data) {
                                                                var lk = Number(vresp.data.lkCnt != null ? vresp.data.lkCnt : (vresp.data.lkcnt != null ? vresp.data.lkcnt : 0)) || 0;
                                                                var ds = Number(vresp.data.dslkCnt != null ? vresp.data.dslkCnt : (vresp.data.dslkcnt != null ? vresp.data.dslkcnt : 0)) || 0;
                                                                $lb.text('👍 ' + lk);
                                                                $db.text('👎 ' + ds);
                                                            } else {
                                                                alert('투표 처리에 실패했습니다. 다시 시도해주세요.');
                                                            }
                                                        } catch (e) { console.error('vote success handler error', e); alert('투표 후 처리 중 오류가 발생했습니다.'); }
                                                    },
                                                    error: function(xhr) { console.error('Vote AJAX error', xhr && xhr.status); alert('서버와 통신할 수 없습니다.'); }
                                                });
                                            } else if (resp && resp.status === 'ERR' && resp.message === 'NOT_LOGGED_IN') {
                                                // shouldn't happen because requireLoginThen ensures login, but handle defensively
                                                alert('로그인이 필요합니다.');
                                            } else {
                                                // unexpected response — still try voting to be permissive
                                                $.ajax({
                                                    url: contextPath + '/review/vote',
                                                    type: 'POST',
                                                    contentType: 'application/json; charset=UTF-8',
                                                    data: JSON.stringify({ isbn: isbnVal, isbn13: isbn13Val, regDt: reg, action: action }),
                                                    success: function(vresp) {
                                                        try {
                                                            if (vresp && vresp.status === 'OK' && vresp.data) {
                                                                var lk = Number(vresp.data.lkCnt != null ? vresp.data.lkCnt : (vresp.data.lkcnt != null ? vresp.data.lkcnt : 0)) || 0;
                                                                var ds = Number(vresp.data.dslkCnt != null ? vresp.data.dslkCnt : (vresp.data.dslkcnt != null ? vresp.data.dslkcnt : 0)) || 0;
                                                                $lb.text('👍 ' + lk);
                                                                $db.text('👎 ' + ds);
                                                            } else {
                                                                alert('투표 처리에 실패했습니다. 다시 시도해주세요.');
                                                            }
                                                        } catch (e) { console.error('vote fallback handler error', e); alert('투표 후 처리 중 오류가 발생했습니다.'); }
                                                    },
                                                    error: function() { alert('서버와 통신할 수 없습니다.'); }
                                                });
                                            }
                                        } catch (e) { console.error('reaction check handler error', e); alert('서버 응답 처리 중 오류가 발생했습니다.'); }
                                    },
                                    error: function() { alert('서버와 통신할 수 없습니다.'); }
                                });
                            }

                            $lb.on('click', function(e){
                                e.preventDefault();
                                requireLoginThen(function(){ doVote('like'); }, { type: 'vote', item: { isbn: isbnVal, isbn13: isbn13Val } });
                            });

                            $db.on('click', function(e){
                                e.preventDefault();
                                requireLoginThen(function(){ doVote('dislike'); }, { type: 'vote', item: { isbn: isbnVal, isbn13: isbn13Val } });
                            });
                        })($likeBtn, $dislikeBtn, rv);
                        $voteWrap.append($likeBtn).append($dislikeBtn);
                        $header.append($nickname).append($rating).append($voteWrap);
                        var $comnet = $('<div>').addClass('review-comnet').css('color', '#222').css('font-size','14px').css('margin','4px 0').text(comnetVal);
                        var $text = $('<div>').addClass('review-text').css('color', '#555').css('font-size','13px').text(reviewVal);
                        if (comnetVal && String(comnetVal).trim().length>0) $item.append($header).append($comnet).append($text);
                        else $item.append($header).append($text);
                        $list.append($item);
                    }
                } catch (e) { console.error('review list render error', e); $noReviews.text('리뷰 로드 중 오류가 발생했습니다.').show(); }
            },
            error: function(xhr) { console.error('Review list AJAX error', xhr.status); $noReviews.text('리뷰 로드 중 오류가 발생했습니다.').show(); }
        });
    }

    // Load reviews initially
    loadReviewList();

    // --- book summary section: fetch and display ---
    function loadBookSummary() {
        var isbnVal = '<%=b != null && b.getIsbn() != null ? b.getIsbn() : ""%>';
        var isbn13Val = '<%=b != null && b.getIsbn13() != null ? b.getIsbn13() : ""%>';
			var payload = {
				isbn : (isbnVal && isbnVal.toString().trim().length > 0) ? isbnVal
						.toString().trim()
						: '',
				isbn13 : (isbn13Val && isbn13Val.toString().trim().length > 0) ? isbn13Val
						.toString().trim()
						: ''
			};
			if ((payload.isbn && payload.isbn.toString().trim().length > 0)
					|| (payload.isbn13 && payload.isbn13.toString().trim().length > 0)) {
				$
						.ajax({
							url : contextPath + '/review/summary',
							type : 'POST',
							contentType : 'application/json; charset=UTF-8',
							data : JSON.stringify(payload),
							success : function(resp) {
								try {
									if (resp && resp.status === 'OK'
											&& resp.data) {
										var summary = resp.data;
										var avgRating = summary.avgRating != null ? Number(
												summary.avgRating).toFixed(1)
												: '-';
										var likeCount = summary.likeCount != null ? summary.likeCount
												: 0;
										var readCount = summary.readCount != null ? summary.readCount
												: 0;
										$('#summary_rating_val')
												.text(avgRating);
										$('#summary_rvw_cnt').text(likeCount);
										$('#summary_read_cnt').text(readCount);
									}
								} catch (e) {
									console.error('summary load handler error',
											e);
								}
							},
							error : function(xhr) {
								console.error('Summary AJAX error', xhr.status);
							}
						});
			}
		}
	</script>

</body>
</html>
