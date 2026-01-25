
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
                error: function(xhr) { console.error('[Î≤†Ïä§?∏Ï??? ?∏Ï∂ú ?§Ìå®', xhr.status); }
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
            $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Í≤Ä??Í≤∞Í≥ºÍ∞Ä ?ÜÏäµ?àÎã§.</p>");
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
            const $likeBtn = $("<button class='btn btn-rvw' type='button' aria-pressed='false' title='Í∞êÏÉÅ?? aria-label='Í∞êÏÉÅ??>?í¨</button>");
            const $readBtn = $("<button class='btn btn-read' type='button' aria-pressed='false' title='?ΩÏùå' aria-label='?ΩÏùå'>?ìñ</button>");
            if (liked) { $likeBtn.addClass('active').attr('aria-pressed','true'); }
            if (read) { $readBtn.addClass('active').attr('aria-pressed','true'); }

            $actionsDiv.append("<span class='summary-badge' title='?âÍ∑† ?âÏ†ê' style='margin-right:8px;'><span>?âÏ†ê : </span> <span class='big summary-rating-val'>-</span></span>");
            $actionsDiv.append($likeBtn);
            $actionsDiv.append($readBtn);
            var $wishBtn = $("<button class='btn btn-wish' type='button' aria-pressed='false' title='?ÑÏãúÎ¶¨Ïä§?? aria-label='?ÑÏãúÎ¶¨Ïä§??>?íñ</button>");
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
            if (!tmdbResp) { $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Í≤Ä??Í≤∞Í≥ºÍ∞Ä ?ÜÏäµ?àÎã§.</p>"); return; }
            // TMDB returns { page, results: [ ... ], total_results, total_pages }
            var results = tmdbResp.results || [];
            if (!Array.isArray(results) || results.length === 0) { $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Í≤Ä??Í≤∞Í≥ºÍ∞Ä ?ÜÏäµ?àÎã§.</p>"); return; }

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
                    $titleLink.append($("<div class='info-title'></div>").text(movie.title || movie.name || '?úÎ™© ?ÜÏùå'));
                    $detailsTd.append($titleLink);

                    var $meta = $("<div class='info-meta'></div>");
                    $meta.append($("<div class='info-author'></div>").text((movie.release_date ? movie.release_date : '') ));
                    $meta.append($("<div class='info-publisher-date'></div>").text(movie.original_language ? (movie.original_language.toUpperCase()) : ''));
                    $detailsTd.append($meta);

                    var $actions = $("<div class='info-actions'></div>");
                    // Add movie-specific actions: rating summary, review, watched, wishlist
                    $actions.append("<span class='summary-badge' title='?âÍ∑† ?âÏ†ê' style='margin-right:8px;'><span>?âÏ†ê : </span> <span class='big summary-rating-val'>-</span></span>");
                    var $rvwBtn = $("<button class='btn btn-rvw' type='button' aria-pressed='false' title='Í∞êÏÉÅ?? aria-label='Í∞êÏÉÅ??>?í¨</button>");
                    var $watchBtn = $("<button class='btn btn-read' type='button' aria-pressed='false' title='?ÅÌôî Î¥? aria-label='?ÅÌôî Î¥?>?é¨</button>");
                    var $wishBtnMovie = $("<button class='btn btn-wish' type='button' aria-pressed='false' title='?ÑÏãúÎ¶¨Ïä§?? aria-label='?ÑÏãúÎ¶¨Ïä§??>?íñ</button>");
                    $actions.append($rvwBtn).append($watchBtn).append($wishBtnMovie);
                    // hidden identifiers for movie rows
                    $detailsTd.append("<input type=\"hidden\" class=\"item-movie-id\" value=\"" + (movie.id || '') + "\">");
                    $detailsTd.append("<input type=\"hidden\" class=\"item-movie-title\" value=\"" + (movie.title || '') + "\">");
                    $detailsTd.append("<input type=\"hidden\" class=\"item-movie-release\" value=\"" + (movie.release_date || '') + "\">");
                    // ensure wishlist local sync
                    try { if (localStorage.getItem(makeStorageKey('mn_wish_movie', String(movie.id || ''))) === '1') { $wishBtnMovie.addClass('active').attr('aria-pressed','true'); } } catch(e) {}

                    $detailsTd.append($actions);

                    $tr.append($coverTd).append($detailsTd);
                    $table.append($tr);
                } catch(e) { console.error('renderMovieResults row error', e); }
            });

            $('#resultArea').html($table);

            // After inserting movie rows, ask server for review statuses for these movie IDs
            try {
                var mvIds = [];
                $table.find('tr').each(function(){
                    try {
                        var id = $(this).attr('data-movie-id') || $(this).find('.item-movie-id').val() || '';
                        if (id && String(id).trim().length > 0) mvIds.push(id);
                    } catch(e) {}
                });
                if (mvIds.length > 0) {
                    $.ajax({
                        url: contextPath + '/review/status',
                        type: 'POST',
                        contentType: 'application/json; charset=UTF-8',
                        data: JSON.stringify({ mvIds: mvIds }),
                        success: function(resp) {
                            try {
                                if (resp && resp.status === 'OK' && resp.data) {
                                    // resp.data may be keyed by mvId or be an array of status rows. Handle both shapes.
                                    (function(){
                                        function pickAvg(st) {
                                            if (!st) return null;
                                            var candidates = ['avgRating','avg','ratingAvg','average','AVG_RATING','AVG','avg_rating'];
                                            for (var i=0;i<candidates.length;i++) { if (typeof st[candidates[i]] !== 'undefined') return st[candidates[i]]; }
                                            return null;
                                        }

                                        function pickMovieIdFromRow(st, fallbackKey) {
                                            if (!st) return fallbackKey;
                                            return st.MV_ID || st.mv_id || st.mvId || st.movieId || st.MV || fallbackKey;
                                        }

                                        var entries = resp.data;
                                        if (Array.isArray(entries)) {
                                            entries.forEach(function(st){
                                                try {
                                                    if (!st) return;
                                                    // unwrap common wrapper { data: { ... } }
                                                    if (st.data && typeof st.data === 'object') st = st.data;
                                                    // defensive: if st still doesn't look like a status, log and skip
                                                    if (!st || (typeof st !== 'object')) { try { console.debug('[movie status] skipped invalid entry', st); } catch(e){} return; }
                                                    var idVal = pickMovieIdFromRow(st, null);
                                                    if (!idVal) return; // can't match a row without id

                                                    // avg
                                                    try {
                                                        var avgVal = pickAvg(st);
                                                        if (avgVal != null && String(avgVal).trim().length > 0 && !isNaN(Number(avgVal))) {
                                                            var disp = Number(avgVal).toFixed(1);
                                                            var $rAvg = $("tr[data-movie-id='" + idVal + "']");
                                                            if ($rAvg && $rAvg.length) { $rAvg.find('.summary-rating-val').first().text(disp); }
                                                        }
                                                    } catch(e) { /* ignore */ }

                                                    // hasReview
                                                    var hasReview = false;
                                                    try {
                                                        var ratingVal = (typeof st.rating !== 'undefined') ? st.rating : (typeof st.RATING !== 'undefined' ? st.RATING : null);
                                                        var cmntVal = (typeof st.cmnt !== 'undefined') ? st.cmnt : (typeof st.CMNT !== 'undefined' ? st.CMNT : (typeof st.comment !== 'undefined' ? st.comment : null));
                                                        var reviewTextVal = (typeof st.reviewText !== 'undefined') ? st.reviewText : (typeof st.REVIEW_TEXT !== 'undefined' ? st.REVIEW_TEXT : (typeof st.text !== 'undefined' ? st.text : null));
                                                        try { if (ratingVal != null && String(ratingVal).trim().length > 0) hasReview = true; } catch(e){}
                                                        try { if (!hasReview && cmntVal != null && String(cmntVal).trim().length > 0) hasReview = true; } catch(e){}
                                                        try { if (!hasReview && reviewTextVal != null && String(reviewTextVal).trim().length > 0) hasReview = true; } catch(e){}
                                                    } catch(e) { /* ignore */ }

                                                    // hasRead
                                                    var hasRead = false;
                                                    try {
                                                        var readVal = null;
                                                        if (typeof st.readYn !== 'undefined') readVal = st.readYn;
                                                        else if (typeof st.READ_YN !== 'undefined') readVal = st.READ_YN;
                                                        else if (typeof st.read !== 'undefined') readVal = st.read;
                                                        else if (typeof st.readCount !== 'undefined') readVal = st.readCount;
                                                        if (readVal != null) {
                                                            try { var s = String(readVal).trim(); if (s.length>0 && (s === 'Y' || s === 'y' || s === '1' || s.toLowerCase() === 'true' || (!isNaN(Number(s)) && Number(s)>0))) hasRead = true; } catch(e){}
                                                        }
                                                    } catch(e) { /* ignore */ }

                                                    // apply UI
                                                    try { var $row = $("tr[data-movie-id='" + idVal + "']"); if ($row && $row.length) { if (hasReview) $row.find('.btn-rvw').first().addClass('active').attr('aria-pressed','true'); if (hasRead) $row.find('.btn-read').first().addClass('active').attr('aria-pressed','true'); } } catch(e){}
                                                } catch(e) { /* per-entry ignore */ }
                                            });
                                        } else {
                                            Object.keys(entries).forEach(function(k) {
                                                try {
                                                    var st = entries[k];
                                                    if (!st) return;
                                                    if (st.data && typeof st.data === 'object') st = st.data;
                                                    if (!st || (typeof st !== 'object')) { try { console.debug('[movie status] skipped invalid keyed entry', k, entries[k]); } catch(e){} return; }
                                                    // pick movie id from object when possible (st may include MV_ID), otherwise use the key
                                                    var idVal = pickMovieIdFromRow(st, k);

                                                    // avg
                                                    try {
                                                        var avgVal = pickAvg(st);
                                                        if (avgVal != null && String(avgVal).trim().length > 0 && !isNaN(Number(avgVal))) {
                                                            var disp = Number(avgVal).toFixed(1);
                                                            var $rAvg = $("tr[data-movie-id='" + idVal + "']");
                                                            if ($rAvg && $rAvg.length) { $rAvg.find('.summary-rating-val').first().text(disp); }
                                                        }
                                                    } catch(e) { /* ignore */ }

                                                    // hasReview
                                                    var hasReview = false;
                                                    try {
                                                        var ratingVal = (typeof st.rating !== 'undefined') ? st.rating : (typeof st.RATING !== 'undefined' ? st.RATING : null);
                                                        var cmntVal = (typeof st.cmnt !== 'undefined') ? st.cmnt : (typeof st.CMNT !== 'undefined' ? st.CMNT : (typeof st.comment !== 'undefined' ? st.comment : null));
                                                        var reviewTextVal = (typeof st.reviewText !== 'undefined') ? st.reviewText : (typeof st.REVIEW_TEXT !== 'undefined' ? st.REVIEW_TEXT : (typeof st.text !== 'undefined' ? st.text : null));
                                                        try { if (ratingVal != null && String(ratingVal).trim().length > 0) hasReview = true; } catch(e){}
                                                        try { if (!hasReview && cmntVal != null && String(cmntVal).trim().length > 0) hasReview = true; } catch(e){}
                                                        try { if (!hasReview && reviewTextVal != null && String(reviewTextVal).trim().length > 0) hasReview = true; } catch(e){}
                                                    } catch(e) { /* ignore */ }

                                                    // hasRead
                                                    var hasRead = false;
                                                    try {
                                                        var readVal = null;
                                                        if (typeof st.readYn !== 'undefined') readVal = st.readYn;
                                                        else if (typeof st.READ_YN !== 'undefined') readVal = st.READ_YN;
                                                        else if (typeof st.read !== 'undefined') readVal = st.read;
                                                        else if (typeof st.readCount !== 'undefined') readVal = st.readCount;
                                                        if (readVal != null) {
                                                            try { var s = String(readVal).trim(); if (s.length>0 && (s === 'Y' || s === 'y' || s === '1' || s.toLowerCase() === 'true' || (!isNaN(Number(s)) && Number(s)>0))) hasRead = true; } catch(e){}
                                                        }
                                                    } catch(e) { /* ignore */ }

                                                    // apply UI
                                                    try { var $row = $("tr[data-movie-id='" + idVal + "']"); if ($row && $row.length) { if (hasReview) $row.find('.btn-rvw').first().addClass('active').attr('aria-pressed','true'); if (hasRead) $row.find('.btn-read').first().addClass('active').attr('aria-pressed','true'); } } catch(e){}
                                                } catch(e) { /* ignore per-key errors */ }
                                            });
                                        }
                                    })();
                                }
                            } catch(e) { console.error('movie status handler error', e); }
                        },
                        error: function() { /* ignore status lookup failures */ }
                    });

                    // Additionally, request per-movie summary (avgRating) because /review/status returns user-specific status not the aggregate
                    try {
                        mvIds.forEach(function(mid) {
                            try {
                                $.ajax({
                                    url: contextPath + '/review/summary',
                                    type: 'POST',
                                    contentType: 'application/json; charset=UTF-8',
                                    data: JSON.stringify({ mvId: mid }),
                                    success: function(sresp) {
                                        try {
                                            if (sresp && sresp.status === 'OK' && sresp.data) {
                                                var avg = null;
                                                if (typeof sresp.data.avgRating !== 'undefined') avg = sresp.data.avgRating;
                                                else if (typeof sresp.data.avg !== 'undefined') avg = sresp.data.avg;
                                                else if (typeof sresp.data.average !== 'undefined') avg = sresp.data.average;
                                                if (avg != null && String(avg).trim().length>0 && !isNaN(Number(avg))) {
                                                    var disp = Number(avg).toFixed(1);
                                                    try { var $r = $("tr[data-movie-id='" + mid + "']"); if ($r && $r.length) $r.find('.summary-rating-val').first().text(disp); } catch(e) { console.error('apply movie summary to row error', e); }
                                                }
                                            }
                                        } catch(e) { console.error('movie summary parse error', e); }
                                    },
                                    error: function() { /* ignore per-movie summary failures */ }
                                });
                            } catch(e) { /* ignore individual mid errors */ }
                        });
                    } catch(e) { console.error('movie summary batch error', e); }
                }
            } catch(e) { console.error('movie status lookup error', e); }
     
    // performSearch: query the server-side search endpoint and render results
    function performSearch() {
        try {
            var q = ($query.val() || '').toString().trim();
            var mt = ($mediaType.val() || '').toString();
            if (!q || q.length === 0) { alert('Í≤Ä?âÏñ¥Î•??ÖÎ†•?¥Ï£º?∏Ïöî.'); return; }
            try { saveSearchState(); } catch(e) {}

            $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Î°úÎî© Ï§?..</p>");

            if (mt === 'movie') {
                $.ajax({
                    url: contextPath + '/movie/search',
                    type: 'GET',
                    data: { query: q },
                    dataType: 'json',
                    success: function(response) {
                        try {
                            if (response && response.status === 'ERR') {
                                $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>?ÅÌôî Í≤Ä?âÏùÑ Ï≤òÎ¶¨?????ÜÏäµ?àÎã§: " + (response.message||'') + "</p>");
                                return;
                            }
                            renderMovieResults(response);
                        } catch (e) { console.error('movie search render error', e); $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>?ÅÌôî Í≤∞Í≥ºÎ•?Ï≤òÎ¶¨?????ÜÏäµ?àÎã§.</p>"); }
                    },
                    error: function(xhr) {
                        console.error('?ÅÌôî Í≤Ä???∏Ï∂ú ?§Ìå®', xhr && xhr.status);
                        $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>?ÅÌôî Í≤Ä??Ï§??§Î•òÍ∞Ä Î∞úÏÉù?àÏäµ?àÎã§.</p>");
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
                        $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Í≤Ä??Í≤∞Í≥ºÎ•?Ï≤òÎ¶¨?????ÜÏäµ?àÎã§.</p>");
                    }
                },
                error: function(xhr) {
                    console.error('Í≤Ä???∏Ï∂ú ?§Ìå®', xhr && xhr.status);
                    $('#resultArea').html("<p style='padding:40px; color:#999; text-align:center;'>Í≤Ä??Ï§??§Î•òÍ∞Ä Î∞úÏÉù?àÏäµ?àÎã§.</p>");
                }
            });
        } catch (e) { console.error('performSearch error', e); }
    }

    // Bind search form submit (Enter key) to performSearch
    $searchForm.on('submit', function(e){ e.preventDefault(); performSearch(); });

    // Save state when clicking result links
    $(document).on('click', '#resultArea .mn-item-link', function() { try { saveSearchState(); } catch(e){} });
    $(document).on('mousedown', '#resultArea .mn-item-link', function(e) { try { saveSearchState(); } catch(e){} });
    $(document).on('auxclick', '#resultArea .mn-item-link', function(e) { try { saveSearchState(); } catch(e){} });

    // Ensure bestsellers are fetched on initial ready if nothing rendered yet.
    (function ensureInitialBestsellers() {
        try {
            setTimeout(function() {
                try {
                    var $res = $('#resultArea');
                    var isEmpty = !$res || $res.children().length === 0 || ($res.text() || '').trim().length === 0;
                    if (isEmpty && !initialBestsellerLoaded) {
                        fetchBestsellers();
                        initialBestsellerLoaded = true;
                    }
                } catch (e) { console.warn('ensureInitialBestsellers check failed', e); }
            }, 120);
        } catch (e) { /* ignore */ }
    })();

    // Immediate fallback
    try {
        var $resNow = $('#resultArea');
        var nowEmpty = !$resNow || $resNow.children().length === 0 || ($resNow.text() || '').trim().length === 0;
        if (nowEmpty && !initialBestsellerLoaded) { fetchBestsellers(); initialBestsellerLoaded = true; }
    } catch(e) {}

    // Load-time fallback
    try { window.addEventListener('load', function(){ try { var $resLoad = $('#resultArea'); var loadEmpty = !$resLoad || $resLoad.children().length === 0 || ($resLoad.text() || '').trim().length === 0; if (loadEmpty && !initialBestsellerLoaded) { fetchBestsellers(); initialBestsellerLoaded = true; } } catch(e){} }); } catch(e) {}

    // Expose helpers and start-up pending processing (kept minimal and robust)
    try {
        var savedSearchRaw = localStorage.getItem('mn_search_state');
        if (savedSearchRaw) {
            try { var saved = JSON.parse(savedSearchRaw); if (saved && (saved.mediaType || saved.query)) { try { if (saved.mediaType) $mediaType.val(saved.mediaType); } catch(e){} try { if (saved.query) $query.val(saved.query); } catch(e){} performSearch(); restoredSearchDone = true; try { localStorage.removeItem('mn_search_state'); } catch(e){} } } catch(e) { console.error('Failed to parse saved search state', e); }
        }

        // Pending action restoration handled later after auth check
        var pendingRaw = localStorage.getItem('mn_pending_action');
        var pending = null;
        if (pendingRaw) {
            try { pending = JSON.parse(pendingRaw); } catch (e) { try { localStorage.removeItem('mn_pending_action'); } catch(e){} pending = null; }
        }

        $.get(contextPath + '/auth/check', function(resp) {
            if (resp === 'OK') {
                try {
                    var ss = localStorage.getItem('mn_search_state');
                    if (ss) {
                        try { var sObj = JSON.parse(ss); if (sObj && (sObj.mediaType || sObj.query) && !restoredSearchDone) { try { if (sObj.mediaType) $mediaType.val(sObj.mediaType); } catch(e){} try { if (sObj.query) $query.val(sObj.query); } catch(e){} performSearch(); } } catch(e) { console.error('Error parsing saved search on restore', e); }
                        try { localStorage.removeItem('mn_search_state'); } catch(e){}
                    }
                } catch(e) { console.error('Error restoring saved search', e); }

                try {
                    if (pending && pending.type === 'like' && pending.item) {
                        var pItem = pending.item;
                        if (pItem.mvId && String(pItem.mvId).trim().length > 0) {
                            $.ajax({ url: contextPath + '/review/status', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify({ mvIds: [pItem.mvId] }), success: function(resp){ var statusObj = null; try{ if (resp && resp.status === 'OK' && resp.data) statusObj = resp.data[String(pItem.mvId)]; }catch(e){} openEditReviewModal(pItem, null, statusObj); }, error: function(){ openEditReviewModal(pItem, null, null); } });
                        } else {
                            var payload = { isbns: [], isbns13: [] };
                            if (pItem.isbn) payload.isbns.push(pItem.isbn);
                            if (pItem.isbn13) payload.isbns13.push(pItem.isbn13);
                            $.ajax({ url: contextPath + '/review/status', type: 'POST', contentType: 'application/json; charset=UTF-8', data: JSON.stringify(payload), success: function(resp){ var statusObj = null; try{ if (resp && resp.status === 'OK' && resp.data) statusObj = findStatusForItem(resp.data, pItem); }catch(e){} openEditReviewModal(pItem, null, statusObj); }, error: function(){ openEditReviewModal(pItem, null, null); } });
                        }
                    }
                } catch(e) { console.error('Failed to resume pending action', e); }
            }
            try { localStorage.removeItem('mn_pending_action'); } catch(e){}
        }).fail(function(){ try { localStorage.removeItem('mn_pending_action'); } catch(e){} });
    } catch(e) { console.error('startup restore error', e); }

});

