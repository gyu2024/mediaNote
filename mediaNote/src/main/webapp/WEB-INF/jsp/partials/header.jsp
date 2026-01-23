<%-- Common header partial: user badge + logo --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<header class="site-header">
    <!-- Left-top site notice button -->
    <div class="site-notice">
        <button id="siteNoticeBtn" class="notice-btn" type="button" aria-haspopup="dialog" aria-controls="noticeModal" title="공지사항">공지사항</button>
    </div>
    <div class="user-badge">
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
        <!-- Build login link on the client so we can include the current path as returnUrl without server-side encoding issues -->
        <a id="mnLoginLink" style="color:#0366d6; text-decoration:none; font-weight:700; margin: 0px 8px 0px ;" href="#">로그인</a>
        <script>
            (function(){
                try {
                    var a = document.getElementById('mnLoginLink');
                    var ctx = '<%= request.getContextPath() %>';
                    var returnUrl = location.pathname + (location.search || '');
                    var href = ctx + '/login/kakao';
                    try { href += '?returnUrl=' + encodeURIComponent(returnUrl); } catch(e) {}
                    a.setAttribute('href', href);
                } catch(e) { }
            })();
        </script>
    <% } %>
    </div>

    <a class="logo" href="<%= request.getContextPath() %>/" aria-label="MediaNote 홈">MediaNote</a>
</header>

<!-- Notice modal (re-usable mn-modal styles are in css/style.css) -->
<div id="noticeModal" class="mn-modal-overlay" aria-hidden="true" role="dialog" aria-modal="true" aria-labelledby="noticeModalTitle">
    <div class="mn-modal" role="document">
        <header class="mn-modal-header">
            <h3 id="noticeModalTitle">공지사항</h3>
            <button class="mn-modal-close" aria-label="닫기" type="button">✕</button>
        </header>
        <section class="mn-modal-body">
            <div id="noticeListContainer" style="font-size:14px; color:#333; line-height:1.5;">
                <p id="noticeLoading" style="color:#777;">로딩 중...</p>
                <div id="noticeError" style="color:#c33; display:none;">공지사항을 불러오지 못했습니다.</div>
                <div id="noticeTableWrapper" style="display:none; max-height:360px; overflow-y:auto;">
                    <table id="noticePreviewTable" style="width:100%; border-collapse:collapse; table-layout:fixed;">
                        <colgroup>
                            <col style="width:65px;" />
                            <col />
                        </colgroup>
                        <thead style="display:none;"></thead>
                        <tbody></tbody>
                    </table>
                </div>
            </div>
         </section>
        <footer class="mn-modal-footer">
            <button class="mn-btn mn-btn-secondary" type="button">닫기</button>
        </footer>
    </div>
</div>

<script>
    (function(){
        // debug marker to confirm the script executed
        try { console.debug('[NOTICE] header.js script loaded'); } catch(e) {}

        try {
            var openBtn = document.getElementById('siteNoticeBtn');
            var overlay = document.getElementById('noticeModal');
            if (!openBtn || !overlay) return;
            var closeBtns = overlay.querySelectorAll('.mn-modal-close, .mn-btn.mn-btn-secondary');
            function openModal() { overlay.style.display = 'flex'; overlay.setAttribute('aria-hidden','false'); }
            function closeModal() { overlay.style.display = 'none'; overlay.setAttribute('aria-hidden','true'); }
            // When opening, show modal and immediately fetch notices (reliable)
            openBtn.addEventListener('click', function(e){ e.preventDefault(); try { openModal(); fetchNoticeList(); } catch(err) { console.error('open+fetch failed', err); } });
            closeBtns.forEach(function(b){ b.addEventListener('click', function(e){ e.preventDefault(); closeModal(); }); });
            // click backdrop to close
            overlay.addEventListener('click', function(e){ if (e.target === overlay) closeModal(); });
            // ESC to close
            document.addEventListener('keydown', function(e){ if ((e.key === 'Escape' || e.key === 'Esc') && overlay.style.display === 'flex') { closeModal(); } });
        } catch (e) { console.error('notice modal init error', e); }

        // visible debug helper in modal (helps when user reports "nothing shows")
        try {
            var _nd = document.getElementById('noticeLoading');
            if (_nd) _nd.textContent = '로딩 중... (스크립트 로드됨)';
        } catch(e) {}

        // simple DOM-based sanitizer: removes <script> elements and inline event handlers (on*) and javascript: hrefs
        function sanitizeHTML(input) {
            if (!input) return '';
            try {
                var container = document.createElement('div');
                container.innerHTML = input;
                // remove script tags
                var scripts = container.querySelectorAll('script');
                scripts.forEach(function(s){ s.parentNode.removeChild(s); });
                // remove event handler attributes and javascript: hrefs
                var all = container.getElementsByTagName('*');
                for (var i = 0; i < all.length; i++) {
                    var attrs = all[i].attributes;
                    for (var j = attrs.length - 1; j >= 0; j--) {
                        var name = attrs[j].name;
                        var val = attrs[j].value || '';
                        if (/^on/i.test(name)) {
                            all[i].removeAttribute(name);
                        } else if (name.toLowerCase() === 'href' && /^javascript:/i.test(val)) {
                            all[i].removeAttribute('href');
                        }
                    }
                }
                return container.innerHTML;
            } catch (e) {
                // Fallback: strip script tags with regex (best-effort)
                return String(input).replace(/<script[\s\S]*?>[\s\S]*?<\/script>/gi, '');
            }
        }

        // helper: escape text for safe insertion into innerHTML when needed
        function escapeHtml(str) {
            if (str == null) return '';
            return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }

        // helper: parse various regDt formats and return {datePart, timePart}
        function formatRegDtString(regDt) {
        	console.log("formatRegDtString called with regDt: " + regDt);
            if (!regDt) return {datePart:'', timePart:''};
            try {
                // If regDt contains comma-separated numeric parts like '2026,1,19,14,51,11'
                if (typeof regDt === 'string') {
                	console.log("regDt is a string");
                    var nums = regDt.match(/\d+/g);
                    if (nums && nums.length >= 6) {
                        var y = nums[0];
                        var m = String(parseInt(nums[1],10));
                        var d = String(parseInt(nums[2],10));
                        var hh = String(parseInt(nums[3],10)).padStart(2,'0');
                        var mm = String(parseInt(nums[4],10)).padStart(2,'0');
                        var ss = String(parseInt(nums[5],10)).padStart(2,'0');
                        
                        console.log("Parsed regDt - y: " + y + ", m: " + m + ", d: " + d + ", hh: " + hh + ", mm: " + mm + ", ss: " + ss);
                        return {datePart: y + '.' + m + '.' + d, timePart: hh + ':' + mm + ':' + ss};
                    }
                } else if (Array.isArray(regDt)) {
                    console.log("regDt is an Array");
                    
                    // 이미 배열이므로 split 할 필요 없이 바로 parts에 할당합니다.
                    const parts = regDt;
                    
                    // 2. 각 항목을 변수에 할당 (배열의 각 요소는 숫자일 수 있으므로 String()으로 감싸줍니다)
                    const y = String(parts[0]);
                    // 1 -> 01 처리를 원하시면 padStart를 유지하시고, 1 -> 1 형식을 원하시면 padStart를 빼세요.
                    const m = String(parts[1]); 
                    const d = String(parts[2]);
                    
                    // 시간은 보통 2자리 형식을 지키므로 padStart를 사용합니다.
                    const hh = String(parts[3] || 0).padStart(2, '0');
                    const mm = String(parts[4] || 0).padStart(2, '0');
                    const ss = String(parts[5] || 0).padStart(2, '0');
                    
                    console.log("Parsed regDt Array - y: " + y + ", m: " + m + ", d: " + d + ", hh: " + hh + ", mm: " + mm + ", ss: " + ss);
                    
                    return {
                        datePart: y + '.' + m + '.' + d, 
                        timePart: hh + ':' + mm + ':' + ss
                    };
                } else if(regDt instanceof Date){
                	console.log("regDt is a Date object3");
                    var y1 = regDt.getFullYear();
                    var m1 = String(regDt.getMonth()+1);
                    var d1 = String(regDt.getDate());
                    var hh1 = String(regDt.getHours()).padStart(2,'0');
                    var mm1 = String(regDt.getMinutes()).padStart(2,'0');
                    var ss1 = String(regDt.getSeconds()).padStart(2,'0');
                    console.log("Parsed regDt - y: " + y1 + ", m: " + m1 + ", d: " + d1 + ", hh: " + hh1 + ", mm: " + mm1 + ", ss: " + ss1);
                    
                    return {datePart: y1 + '.' + m1 + '.' + d1, timePart: hh1 + ':' + mm1 + ':' + ss1};
                }
                // Try to parse with Date
                var dt = new Date(regDt);
                if (!isNaN(dt.getTime())) {
                	console.log("regDt is a string");
                    var y2 = dt.getFullYear();
                    var m2 = String(dt.getMonth()+1);
                    var d2 = String(dt.getDate());
                    var hh2 = String(dt.getHours()).padStart(2,'0');
                    var mm2 = String(dt.getMinutes()).padStart(2,'0');
                    var ss2 = String(dt.getSeconds()).padStart(2,'0');
                    console.log("Parsed regDt - y: " + y2 + ", m: " + m2 + ", d: " + d2 + ", hh: " + hh2 + ", mm: " + mm2 + ", ss: " + ss2);
                    
                    return {datePart: y2 + '.' + m2 + '.' + d2, timePart: hh2 + ':' + mm2 + ':' + ss2};
                } else {	
                	console.log("regDt could not be parsed as Date");
                	// 1. 콤마를 기준으로 문자열을 배열로 쪼개기
                	const parts = regDt.split(',');

                	// 2. 각 항목을 변수에 할당 (필요에 따라 2자리 숫자 포맷팅 처리)
                	const y = parts[0];
                	const m = parts[1].padStart(2, '0'); // 1 -> 01
                	const d = parts[2].padStart(2, '0'); // 19 -> 19
                	const hh = parts[3].padStart(2, '0');
                	const mm = parts[4].padStart(2, '0');
                	const ss = parts[5].padStart(2, '0');
                	return {datePart: y + '.' + m + '.' + d, timePart: hh + ':' + mm + ':' + ss};
                }
            } catch (e) {}
            // fallback: treat whole regDt as datePart
            return {datePart: String(regDt), timePart: ''};
        }

        // Notice list fetching and rendering
        var noticeListContainer = document.getElementById('noticeListContainer');
        var noticeLoading = document.getElementById('noticeLoading');
        var noticeError = document.getElementById('noticeError');
        var noticeTableWrapper = document.getElementById('noticeTableWrapper');
        var noticePreviewTableEl = document.getElementById('noticePreviewTable');
        var noticePreviewTbody = noticePreviewTableEl ? noticePreviewTableEl.getElementsByTagName('tbody')[0] : null;

        function fetchNoticeList() {
            // Re-query DOM elements inside the fetch to avoid stale references
            var noticeLoading = document.getElementById('noticeLoading');
            var noticeError = document.getElementById('noticeError');
            var noticeTableWrapper = document.getElementById('noticeTableWrapper');
            var noticePreviewTableEl = document.getElementById('noticePreviewTable');
            var noticePreviewTbody = noticePreviewTableEl ? noticePreviewTableEl.getElementsByTagName('tbody')[0] : null;

            if (noticeLoading) noticeLoading.style.display = 'block';
            if (noticeError) noticeError.style.display = 'none';
            if (noticeTableWrapper) noticeTableWrapper.style.display = 'none';

            var xhr = new XMLHttpRequest();
            xhr.open('GET', '<%= request.getContextPath() %>/notice/api/list', true);
            xhr.onreadystatechange = function () {
                if (xhr.readyState === 4) {
                    if (noticeLoading) noticeLoading.style.display = 'none';
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText);
                            if (response && response.status === 'OK' && Array.isArray(response.data)) {
                                renderNoticeList(response.data);
                            } else {
                                var msg = response && response.message ? response.message : ('공지사항 조회에 실패했습니다. (응답:' + xhr.status + ')');
                                showError(msg);
                            }
                        } catch (e) {
                            console.error('parse response failed', e, xhr.responseText);
                            showError('공지사항을 불러오는 중 오류가 발생했습니다.');
                        }
                    } else {
                        console.error('notice api returned status', xhr.status, xhr.responseText);
                        showError('공지사항을 불러오는 데 실패했습니다. 상태 코드: ' + xhr.status);
                    }
                }
            };
            xhr.onerror = function() {
                if (noticeLoading) noticeLoading.style.display = 'none';
                console.error('network error fetching notices');
                showError('네트워크 오류로 공지사항을 불러올 수 없습니다.');
            };
            try { xhr.send(); } catch (e) { console.error('xhr send failed', e); showError('공지사항 요청을 전송하지 못했습니다.'); }
         }

        function renderNoticeList(notices) {
            // Re-query important DOM nodes to avoid stale references
            var noticePreviewTableEl = document.getElementById('noticePreviewTable');
            var noticePreviewTbody = noticePreviewTableEl ? noticePreviewTableEl.getElementsByTagName('tbody')[0] : null;
            var noticeTableWrapper = document.getElementById('noticeTableWrapper');
            var noticeError = document.getElementById('noticeError');
            var noticeLoading = document.getElementById('noticeLoading');

            if (!noticePreviewTbody) {
                console.error('noticePreviewTbody not found');
                if (noticeError) { noticeError.textContent = 'UI 요소를 찾을 수 없습니다.'; noticeError.style.display = 'block'; }
                return;
            }

            noticePreviewTbody.innerHTML = '';
            if (!Array.isArray(notices) || notices.length === 0) {
                var tr = document.createElement('tr');
                var td = document.createElement('td');
                td.colSpan = 2;
                td.style.padding = '8px';
                td.style.color = '#777';
                td.textContent = '등록된 공지사항이 없습니다.';
                tr.appendChild(td);
                noticePreviewTbody.appendChild(tr);
                if (noticeTableWrapper) noticeTableWrapper.style.display = 'block';
                return;
            }

            // render all notices (modal wrapper is scrollable when many items exist)
            for (var i = 0; i < notices.length; i++) {
                var notice = notices[i];
                var id = notice.NOTICE_ID || notice.noticeId || notice.id || notice.NOTICEID || '';
                var title = notice.TITLE || notice.title || notice.Title || '';
                var regDt = notice.REG_DT || notice.reg_dt || notice.regDt || notice.REGDATE || notice.date || '';
                var content = notice.CONTENT || notice.content || notice.Body || notice.BODY || notice.body || '';

                var row = document.createElement('tr');
                row.style.borderBottom = '1px solid #f0f0f0';
                // date cell (left side)
                var dcel = document.createElement('td');
                dcel.style.padding = '8px';
                // slightly wider to accommodate the date/time on two lines
                dcel.style.width = '160px';
                // left align date cell
                dcel.style.textAlign = 'right';
                dcel.style.fontSize = '10px';
                var parts = formatRegDtString(regDt);
                
                console.log("parts - " + parts);
                
                // debug: log the raw regDt and parsed parts so we can verify formatting in browser console
                try { console.debug('[NOTICE] regDt raw:', regDt, 'parsed:', parts); } catch(e) {}
                // render date on first line and time on second line
                if (parts.timePart) {
                    dcel.innerHTML = '<div class="notice-date" style="font-weight:600;">' + escapeHtml(parts.datePart) + '</div>' +
                                    '<div class="notice-time" style="color:#666; margin-top:4px;">' + escapeHtml(parts.timePart) + '</div>';
                } else {
                    dcel.innerHTML = '<div class="notice-date">' + escapeHtml(parts.datePart) + '</div>';
                }

                // title cell
                var tcel = document.createElement('td');
                // ensure title cell content is right-aligned and sits on the right
                tcel.style.padding = '8px';
                // make title cell take remaining width and align contents to right
                tcel.style.width = 'auto';
                tcel.style.textAlign = 'left';

                var a = document.createElement('a');
                // Instead of navigating to a detail page, toggle inline expansion of content
                a.href = '#';
                a.textContent = title || '(제목없음)';
                a.style.color = '#0366d6';
                a.style.textDecoration = 'none';
                a.style.cursor = 'pointer';
                a.setAttribute('role', 'button');
                a.setAttribute('aria-expanded', 'false');
                // wrap the anchor in a right-aligned container to force right placement
                var titleWrap = document.createElement('div');
                titleWrap.style.display = 'block';
                titleWrap.style.width = '100%';
                titleWrap.style.textAlign = 'left';
                titleWrap.style.overflowWrap = 'anywhere';
                titleWrap.style.wordBreak = 'break-word';
                titleWrap.style.boxSizing = 'border-box';
                titleWrap.appendChild(a);

                // show VER_INFO to the right of the title as ' - VER_INFO' when present
                var verInfo = notice.VER_INFO || notice.ver_info || notice.verInfo || notice.ver || '';
                if (verInfo && String(verInfo).trim().length > 0) {
                    var verSpan = document.createElement('span');
                    verSpan.className = 'notice-verinfo';
                    verSpan.textContent = ' - ' + String(verInfo);
                    // exact inline styles per user request (do not change external CSS)
                    verSpan.setAttribute('style', 'color: rgb(136, 136, 136);font-size: 12px;/* margin-left: 6px; */vertical-align: middle;');
                    var verWrap = document.createElement('div');
                    verWrap.appendChild(verSpan);
                    titleWrap.appendChild(verWrap);
                }

                a.addEventListener('click', (function(n, r){
                    return function(e){
                        e.preventDefault();
                        try {
                            // If an expanded row already exists immediately after this row, toggle it
                            var next = r.nextSibling;
                            if (next && next.classList && next.classList.contains('notice-expanded')) {
                                var currentlyHidden = next.style.display === 'none' || next.style.display === '' ? false : false; // keep toggle logic simple
                                if (next.style.display === 'none' || next.style.display === '') {
                                    next.style.display = 'table-row';
                                    this.setAttribute('aria-expanded', 'true');
                                } else {
                                    next.style.display = 'none';
                                    this.setAttribute('aria-expanded', 'false');
                                }
                                return;
                            }

                            // create an expanded row below with full content
                            var er = document.createElement('tr');
                            er.className = 'notice-expanded';
                            var ed = document.createElement('td');
                            ed.colSpan = 2;
                            ed.style.padding = '10px 12px';
                            ed.style.background = '#ffffff';
                            ed.style.color = '#333';
                            ed.style.borderBottom = '1px solid #f0f0f0';

                            var contentDiv = document.createElement('div');
                            contentDiv.className = 'notice-content';
                            contentDiv.style.whiteSpace = 'pre-wrap';
                            contentDiv.style.lineHeight = '1.6';
                            contentDiv.style.fontSize = '13px';
                            contentDiv.style.padding = '0 0 0 15px';
                            // Render sanitized HTML content from the DB into the expanded area
                            // (we sanitize basic dangerous parts like <script> and on* handlers)
                            try {
                                contentDiv.innerHTML = sanitizeHTML(n) || '(내용없음)';
                            } catch(e) {
                                contentDiv.textContent = n || '(내용없음)';
                            }
                            ed.appendChild(contentDiv);
                            er.appendChild(ed);

                            // insert expanded row after the title row
                            if (r.nextSibling) noticePreviewTbody.insertBefore(er, r.nextSibling);
                            else noticePreviewTbody.appendChild(er);
                            this.setAttribute('aria-expanded', 'true');

                            // Keep modal scroll focused: if expanded row is out of view, scroll it into view inside wrapper
                            try { er.scrollIntoView({ block: 'nearest' }); } catch(e) {}
                        } catch (err) { console.error('expand notice failed', err); }
                    };
                })(content, row));

                tcel.appendChild(titleWrap);
                 // if fixed, show badge
                 try {
                     var fix = (notice.FIX_YN || notice.fixYn || notice.FIXY || '').toString();
                     if (fix === 'Y' || fix === 'y') {
                         var span = document.createElement('span');
                         span.textContent = '고정';
                         span.style.background = '#fffae6';
                         span.style.color = '#c77d00';
                         span.style.padding = '2px 6px';
                         span.style.borderRadius = '6px';
                         span.style.marginLeft = '8px';
                         span.style.fontSize = '12px';
                        // append badge into titleWrap so it appears next to title on the right
                        titleWrap.appendChild(span);
                     }
                 } catch (e) {}

                // append date first (left), then title (right)
                row.appendChild(dcel);
                row.appendChild(tcel);
                noticePreviewTbody.appendChild(row);
            }
            if (noticeTableWrapper) noticeTableWrapper.style.display = 'block';
         }

        function showError(message) {
            var noticeError = document.getElementById('noticeError');
            var noticeTableWrapper = document.getElementById('noticeTableWrapper');
            if (noticeError) {
                noticeError.textContent = message;
                noticeError.style.display = 'block';
            }
            if (noticeTableWrapper) noticeTableWrapper.style.display = 'none';
        }

        // (fetch is triggered directly when opening the modal)
    })();
</script>

<!-- Fixed footer: inline-styled (no external CSS changes) -->
<footer role="contentinfo" aria-label="하단 고정 메뉴"
        style="position:fixed;left:0;right:0;bottom:0;height:64px;background:#ffffff;border-top:1px solid rgba(0,0,0,0.06);display:flex;align-items:center;justify-content:space-around;z-index:1300;padding:8px 6px;box-shadow:0 -6px 18px rgba(2,6,23,0.06);">
    <a data-action="home" aria-label="홈" href="<%= request.getContextPath() %>/" style="display:flex;flex-direction:column;align-items:center;justify-content:center;color:#374151;text-decoration:none;width:56px;height:56px;border-radius:12px;transition:background 120ms ease,color 120ms ease;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <path d="M3 10.5L12 3l9 7.5V21a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1V10.5z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span style="font-size:11px;">홈</span>
    </a>

    <a href="#" data-action="search" aria-label="검색"
       style="display:flex;flex-direction:column;align-items:center;justify-content:center;color:#374151;text-decoration:none;width:56px;height:56px;border-radius:12px;transition:background 120ms ease,color 120ms ease;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <circle cx="11" cy="11" r="6" stroke="currentColor" stroke-width="1.2"/>
            <path d="M21 21l-4.35-4.35" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
        </svg>
        <span style="font-size:11px;">검색</span>
    </a>

    <a href="#" data-action="add" aria-label="추가"
       style="display:flex;flex-direction:column;align-items:center;justify-content:center;color:#374151;text-decoration:none;width:56px;height:56px;border-radius:12px;transition:background 120ms ease,color 120ms ease;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <!-- simple bookmark-like icon to match other icon styles -->
            <path d="M6 2h12v16l-6-3-6 3V2z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
        </svg>
        <span style="font-size:11px;">추가</span>
    </a>

    <a href="#" data-action="notice" aria-label="알림"
       style="display:flex;flex-direction:column;align-items:center;justify-content:center;color:#374151;text-decoration:none;width:56px;height:56px;border-radius:12px;transition:background 120ms ease,color 120ms ease;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <path d="M15 17H9a3 3 0 0 0 6 0z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M18 8a6 6 0 0 0-12 0v4l-2 2h16l-2-2V8z" stroke="currentColor" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span style="font-size:11px;">알림</span>
    </a>

    <a href="<%= request.getContextPath() %>/profile.jsp" data-action="profile" aria-label="내정보"
       style="display:flex;flex-direction:column;align-items:center;justify-content:center;color:#374151;text-decoration:none;width:56px;height:56px;border-radius:12px;transition:background 120ms ease,color 120ms ease;">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <circle cx="12" cy="8" r="3" stroke="currentColor" stroke-width="1.2"/>
            <path d="M4 20a8 8 0 0 1 16 0" stroke="currentColor" stroke-width="1.2" stroke-linecap="round"/>
        </svg>
        <span style="font-size:11px;">내정보</span>
    </a>
</footer>

<script>
    // Footer interaction using inline styles (no CSS file changes required)
    (function(){
        try {
            var footer = document.querySelector('footer[aria-label="하단 고정 메뉴"]');
            if (!footer) return;
            var buttons = Array.from(footer.querySelectorAll('a[data-action]'));
            // helper to reset styles to default
            function resetStyles() {
                buttons.forEach(function(b){
                    // make all footer buttons share the same base appearance
                    b.style.width = '56px';
                    b.style.height = '56px';
                    b.style.background = 'transparent';
                    b.style.color = '#374151';
                    b.style.transform = 'translateY(0)';
                    b.style.boxShadow = 'none';
                });
            }
            // initialize default appearance
            resetStyles();

            // Capture-phase handler for profile link: if it has a real href, force navigation as a fallback
            try {
                var profileAnchor = footer.querySelector('a[data-action="profile"]');
                if (profileAnchor) {
                    profileAnchor.addEventListener('click', function(e){
                        try {
                            var hrefAttr = this.getAttribute('href');
                            console.debug('[HEADER] profile click captured; href=', hrefAttr, ' defaultPrevented=', e.defaultPrevented);
                            if (hrefAttr && hrefAttr.trim() !== '#') {
                                // schedule a forced navigation in the next macrotask to bypass other preventDefault handlers
                                setTimeout(function(){ try { window.location.href = hrefAttr; } catch(err) {} }, 0);
                                // don't preventDefault here so normal navigation may proceed; the timeout ensures navigation even if another handler cancels it
                            }
                        } catch (err) { console.error('[HEADER] profile click handler error', err); }
                    }, true); // use capture to run before other listeners
                }
            } catch (e) { /* ignore */ }

            footer.addEventListener('click', function(e){
                var a = e.target.closest('a[data-action]');
                if (!a) return;
                var act = a.getAttribute('data-action');
                // allow the home link to follow the navigation normally
                if (act === 'home') {
                    return; // let the browser follow the href
                }

                // If the anchor has a real href (not '#'), allow normal navigation
                try {
                    var hrefAttr = a.getAttribute('href');
                    if (hrefAttr && hrefAttr.trim() !== '#') {
                        // let browser navigate to the href
                        return;
                    }
                } catch (e) { /* ignore and fall back to client handling */ }

                e.preventDefault();
                resetStyles();
                // uniform active appearance for any non-navigation footer button
                a.style.background = 'rgba(3,102,214,0.08)';
                a.style.color = '#0366d6';
                a.style.boxShadow = 'none';
                a.style.transform = 'translateY(0)';
            });
        } catch (e) { console.error('footer init error', e); }
    })();
</script>