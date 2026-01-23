<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>읽은 책 - MediaNote</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/profile-extras.css">
</head>
<body>
<jsp:include page="/WEB-INF/jsp/partials/header.jsp" />
<main class="container">
    <h2>읽은 책</h2>
    <div id="readArea"><p style="color:#777;">불러오는 중...</p></div>
</main>

<!-- review modal (copied minimal modal from index.jsp) -->
<div id="reviewModal" class="mn-modal-overlay" aria-hidden="true" style="display:none;">
    <div class="mn-modal" role="dialog" aria-modal="true" aria-labelledby="mn-modal-title">
        <header class="mn-modal-header">
            <h3 id="mn-modal-title">리뷰 작성</h3>
            <button class="mn-modal-close" aria-label="닫기" onclick="closeReviewModal()">✕</button>
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
            // collect arrays from object
            var out = [];
            Object.keys(resp).forEach(function(k){ if (Array.isArray(resp[k])) out = out.concat(resp[k]); });
            return out;
        }

        function render(items){
            var $out = $('#readArea');
            $out.empty();
            if (!items || items.length === 0) { $out.html('<p style="color:#777;">읽은 책이 없습니다.</p>'); return; }
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

                // action buttons: 감상평, 읽음, 위시리스트
                var $actions = $('<div class="info-actions"></div>');
                var $rvwBtn = $('<button class="btn btn-rvw" type="button" aria-pressed="false" title="감상평">💬</button>');
                var $readBtn = $('<button class="btn btn-read active" type="button" aria-pressed="true" title="읽음">📖</button>');
                var $wishBtn = $('<button class="btn btn-wish" type="button" aria-pressed="false" title="위시리스트">💖</button>');
                $actions.append($rvwBtn).append($readBtn).append($wishBtn);
                $details.append($actions);

                // hidden inputs for compatibility with index.jsp handlers
                $details.append('<input type="hidden" class="item-isbn" value="' + (item.isbn || '') + '">');
                $details.append('<input type="hidden" class="item-isbn13" value="' + (item.isbn13 || '') + '">');

                $tr.append($coverTd).append($details);
                $table.append($tr);
            });
            $out.append($table);
        }

        // small helpers copied from index.jsp for consistent localStorage keys and auth flow
        function makeStorageKey(prefix, rawKey) {
            try { return prefix + ':' + btoa(unescape(encodeURIComponent(rawKey))); } catch (e) { return prefix + ':' + rawKey; }
        }

        function requireLoginThen(action, pending) {
            $.get(ctx + '/auth/check', function(resp){
                if (resp === 'OK') { action && action(); }
                else {
                    try {
                        if (pending) { pending.returnUrl = location.pathname + (location.search || ''); localStorage.setItem('mn_pending_action', JSON.stringify(pending)); }
                    } catch(e) {}
                    try {
                        var loginHref = ctx + '/login/kakao';
                        loginHref += '?returnUrl=' + encodeURIComponent(location.pathname + (location.search || ''));
                        window.location.href = loginHref;
                    } catch(e){ window.location.href = ctx + '/login/kakao'; }
                }
            });
        }

        // Delegated handlers for action buttons inside #readArea
        $(document).on('click', '#readArea .btn-rvw', function(e){
            e.preventDefault();
            var $btn = $(this);
            var $row = $btn.closest('tr');
            var domIsbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
            var domIsbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
            var titleText = $row.find('.info-title').text() || '';
            var authorText = $row.find('.info-author').text() || '';
            var item = { isbn: domIsbn || '', isbn13: domIsbn13 || '', title: titleText.trim(), author: authorText.trim() };

            requireLoginThen(function(){
                try {
                    if (!$btn.hasClass('active')) {
                        openReviewModal(item, $btn);
                    } else {
                        // fetch existing status and open edit modal
                        var payload = { isbns: [], isbns13: [] };
                        if (item.isbn && item.isbn.toString().trim().length > 0) payload.isbns.push(item.isbn.toString().trim());
                        if (item.isbn13 && item.isbn13.toString().trim().length > 0) payload.isbns13.push(item.isbn13.toString().trim());
                        $.ajax({
                            url: ctx + '/review/status',
                            type: 'POST',
                            contentType: 'application/json; charset=UTF-8',
                            data: JSON.stringify(payload),
                            success: function(resp){
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
                                } catch (e) { console.error('status parse error', e); }
                                openEditReviewModal(item, $btn, statusObj);
                            },
                            error: function(){ openEditReviewModal(item, $btn, null); }
                        });
                    }
                } catch (e) { console.error('btn-rvw handler error', e); openReviewModal(item, $btn); }
            }, { type: 'like', item: item });
        });

        // modal state
        var currentReviewItem = null;
        var currentLikeButton = null;

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
            $('#rvw_rating').val(''); $('#rvw_comnet').val(''); $('#rvw_text').val(''); renderStars('');
            $('#rvw_delete').hide();
            $('#reviewModal').css('display','flex').hide().fadeIn(200);
        }

        function openEditReviewModal(itemObj, $btnRef, status) {
            try {
                var $row = $btnRef ? $btnRef.closest('tr') : null;
                if ($row && $row.length) {
                    if (!itemObj.isbn || itemObj.isbn.trim() === '') itemObj.isbn = $row.attr('data-isbn') || $row.find('.item-isbn').val() || '';
                    if (!itemObj.isbn13 || itemObj.isbn13.trim() === '') itemObj.isbn13 = $row.attr('data-isbn13') || $row.find('.item-isbn13').val() || '';
                    if (!itemObj.title) itemObj.title = $row.find('.info-title').text().trim();
                    if (!itemObj.author) itemObj.author = $row.find('.info-author').text().trim();
                }

                if (status) {
                    var rv = '';
                    if (status.rating != null && status.rating !== '') {
                        try { var num = Number(status.rating); if (!isNaN(num)) rv = num.toFixed(1); else rv = String(status.rating); } catch(e){ rv = String(status.rating); }
                    }
                    try {
                        var $sel = $('#rvw_rating');
                        if (rv && $sel.find('option[value="' + rv + '"]').length === 0) {
                            var n = Number(rv);
                            if (!isNaN(n)) {
                                var rounded = Math.round(n * 2) / 2; var candidate = rounded.toFixed(1);
                                if ($sel.find('option[value="' + candidate + '"]').length > 0) rv = candidate; else {
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
                        var $opt = $sel.find('option[value="' + rv + '"]'); if ($opt.length > 0) $opt.prop('selected', true);
                        $sel.trigger('change');
                    } catch (e) { console.error('rating select set error', e); }
                    $('#rvw_comnet').val(status.cmnt != null ? String(status.cmnt) : '');
                    $('#rvw_text').val(status.reviewText != null ? String(status.reviewText) : '');
                    renderStars(rv);
                    $('#rvw_delete').show();
                } else {
                    $('#rvw_rating').val(''); $('#rvw_comnet').val(''); $('#rvw_text').val(''); renderStars(''); $('#rvw_delete').hide();
                }

                currentReviewItem = itemObj; currentLikeButton = $btnRef;
                $('#reviewModal').css('display','flex').hide().fadeIn(200);
            } catch (e) { console.error('openEditReviewModal error', e); openReviewModal(itemObj, $btnRef); }
        }

        function closeReviewModal() {
            $('#reviewModal').fadeOut(200, function(){ $(this).css('display','none'); try { $('#rvw_rating').find('.temp-rv-option').remove(); } catch(e){} currentReviewItem = null; currentLikeButton = null; });
        }

        // wire modal button handlers
        $(document).on('click', '#rvw_cancel', function(){ closeReviewModal(); });

        $(document).on('click', '#rvw_delete', function(){
            if (!currentReviewItem) { alert('삭제할 항목 정보가 없습니다.'); return; }
            if (!confirm('정말로 리뷰를 삭제하시겠습니까?')) return;
            var payload = { isbn: currentReviewItem.isbn || '', isbn13: currentReviewItem.isbn13 || '' };
            $.ajax({ url: ctx + '/review/delete', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify(payload), success: function(resp){ try { if (resp && resp.status === 'OK') { var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || '')); try{ localStorage.removeItem(makeStorageKey('mn_like', rawKey)); }catch(e){} try{ localStorage.removeItem(makeStorageKey('mn_read', rawKey)); }catch(e){} if (currentLikeButton && currentLikeButton.length) { currentLikeButton.removeClass('active').attr('aria-pressed','false'); try { currentLikeButton.closest('tr').find('.btn-read').removeClass('active').attr('aria-pressed','false'); } catch(e){} } alert('리뷰가 삭제되었습니다.'); closeReviewModal(); } else { alert('리뷰 삭제에 실패했습니다.'); } } catch(e){ console.error('delete handler error', e); alert('리뷰 삭제 중 오류'); } }, error: function(xhr){ console.error('Delete AJAX error', xhr.status); alert('서버와 통신할 수 없습니다.'); } });
        });

        $(document).on('click', '#rvw_save', function(){
            var rating = $('#rvw_rating').val(); var comment = $('#rvw_comnet').val(); var text = $('#rvw_text').val();
            if (!rating) { alert('평점을 선택해주세요.'); return; }
            if (!currentReviewItem) { alert('리뷰할 항목 정보가 없습니다.'); return; }
            var itemIsbn = (currentReviewItem && (currentReviewItem.isbn || currentReviewItem.isbn13)) ? (currentReviewItem.isbn || currentReviewItem.isbn13) : '';
            var fallbackKey = (!itemIsbn && currentReviewItem) ? ((currentReviewItem.title || '') + '|' + (currentReviewItem.author || '')) : '';
            var reviewData = { itemId: itemIsbn, itemKey: fallbackKey, isbn: currentReviewItem && currentReviewItem.isbn ? currentReviewItem.isbn : '', isbn13: currentReviewItem && currentReviewItem.isbn13 ? currentReviewItem.isbn13 : '', title: currentReviewItem && currentReviewItem.title ? currentReviewItem.title : '', author: currentReviewItem && currentReviewItem.author ? currentReviewItem.author : '', rating: rating, comment: comment, text: text };
            if ((!reviewData.itemId || reviewData.itemId.trim() === '') && (!reviewData.itemKey || reviewData.itemKey.trim() === '')) { alert('도서 식별자(ISBN) 또는 항목 정보가 없습니다. 검색에서 해당 항목을 선택한 뒤 다시 시도해주세요.'); return; }
            $.ajax({ url: ctx + '/review/save', type: 'POST', contentType: 'application/x-www-form-urlencoded; charset=UTF-8', data: $.param(reviewData), success: function(response){ try { var rawKey = currentReviewItem.isbn && currentReviewItem.isbn.length ? currentReviewItem.isbn : (currentReviewItem.title + '|' + (currentReviewItem.author || '')); try{ localStorage.setItem(makeStorageKey('mn_like', rawKey), '1'); }catch(e){} try{ localStorage.setItem(makeStorageKey('mn_read', rawKey), '1'); }catch(e){} if (currentLikeButton) { currentLikeButton.addClass('active').attr('aria-pressed','true'); try { currentLikeButton.closest('tr').find('.btn-read').first().addClass('active').attr('aria-pressed','true'); } catch(e){} } closeReviewModal(); alert('리뷰가 저장되었습니다.'); } catch(e){ console.error('save success handler error', e); alert('리뷰 저장 중 오류가 발생했습니다.'); } }, error: function(xhr){ console.error('Review save error', xhr.status); alert('리뷰 저장 중 오류가 발생했습니다.'); } });
        });

        // render stars helper and bindings
        function renderStars(val) { var out=''; if (!val) out='☆☆☆☆☆'; else { var num = Math.floor(Number(val)); for (var i=0;i<num;i++) out += '★'; for (var j=num;j<5;j++) out += '☆'; } var el = document.getElementById('starDisplay'); if (el) el.textContent = out + (val ? ('  ' + val) : ''); }
        $(document).on('change', '#rvw_rating', function(){ renderStars(this.value); });
        // overlay close and ESC handling
        $(document).on('click', '#reviewModal', function(e){ if (e.target === this) closeReviewModal(); });
        $(document).on('keydown', function(e){ if (e.key === 'Escape' || e.key === 'Esc') { var ov = document.getElementById('reviewModal'); if (ov && ov.style.display !== 'none') closeReviewModal(); } });

        // Try server endpoints
        function fetchRead(){
            // try /review/my first
            $.ajax({ url: ctx + '/review/my', type: 'GET', success: function(resp){ var items = normalize(resp); if (items && items.length) { render(items); } else { fetchListFallback(); } }, error: function(){ fetchListFallback(); } });
        }
        function fetchListFallback(){
            $.ajax({ url: ctx + '/review/list', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify({ mine: true }), success: function(resp){ var items = normalize(resp); render(items); }, error: function(){ // fallback to localStorage
                    var items = [];
                    try {
                        for (var i=0;i<localStorage.length;i++){ var k = localStorage.key(i); if (k && k.indexOf('mn_read:')===0){ var enc = k.split(':')[1]||''; try{ var raw = decodeURIComponent(escape(atob(enc))); } catch(e){ try{ raw = atob(enc); } catch(e){ raw = enc; } } var it = { title: raw.split('|')[0]||raw, author: raw.split('|')[1]||'' }; items.push(it); }}
                    } catch(e) {}
                    render(items);
                } });
        }

        $(function(){ fetchRead(); });
    })();
</script>
</body>
</html>
