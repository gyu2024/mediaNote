package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.Map;
import java.util.HashMap;
import com.mn.cm.dao.WishDAO;
import com.mn.cm.model.User;
import java.util.List;

@Controller
@RequestMapping("/wish")
public class WishController {

    @Autowired
    private WishDAO wishDAO;

    private static final Logger logger = LoggerFactory.getLogger(WishController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping(value = "/add", produces = "application/json")
    @ResponseBody
    public Map<String,Object> addWish(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            User u = (User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("mvId") != null) {
                        try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ex) { mvId = null; }
                    }
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pMvId = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pMvId != null && pMvId.trim().length()>0) {
                    try { mvId = Integer.valueOf(pMvId.trim()); } catch(Exception ex) { mvId = null; }
                }
            }

            if (mvId != null) {
                // Movie wish
                wishDAO.insertOrUpdateMovieWish(userId, mvId);
                result.put("status","OK"); return result;
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            String isbnForTable = (isbn != null && isbn.trim().length()>0) ? isbn.trim() : (isbn13 != null ? isbn13.trim() : "");
            String isbn13ForTable = (isbn13 != null && isbn13.trim().length()>0) ? isbn13.trim() : null;

            wishDAO.insertOrUpdateWish(userId, isbnForTable, isbn13ForTable);
            result.put("status","OK");
            return result;
        } catch (Exception ex) {
            logger.error("[WISH ADD] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/remove", produces = "application/json")
    @ResponseBody
    public Map<String,Object> removeWish(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            User u = (User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("mvId") != null) {
                        try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ex) { mvId = null; }
                    }
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pMvId = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pMvId != null && pMvId.trim().length()>0) {
                    try { mvId = Integer.valueOf(pMvId.trim()); } catch(Exception ex) { mvId = null; }
                }
            }

            if (mvId != null) {
                // Movie wish removal
                wishDAO.deleteMovieWish(userId, mvId);
                result.put("status","OK"); return result;
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            String isbnForTable = (isbn != null && isbn.trim().length()>0) ? isbn.trim() : (isbn13 != null ? isbn13.trim() : "");
            String isbn13ForTable = (isbn13 != null && isbn13.trim().length()>0) ? isbn13.trim() : null;

            wishDAO.deleteWish(userId, isbnForTable, isbn13ForTable);
            result.put("status","OK");
            return result;
        } catch (Exception ex) {
            logger.error("[WISH REMOVE] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/count", produces = "application/json")
    @ResponseBody
    public Map<String,Object> countWish(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            String isbn = null; String isbn13 = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            java.util.List<String> isbns = null;
            java.util.List<String> isbns13 = null;
            java.util.List<Integer> mvIds = null;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    // support plural keys used by front-end: isbns / isbns13 / mvIds
                    if (payload.get("isbns") instanceof java.util.List) isbns = (java.util.List<String>) payload.get("isbns");
                    if (payload.get("isbns13") instanceof java.util.List) isbns13 = (java.util.List<String>) payload.get("isbns13");
                    if (payload.get("mvIds") instanceof java.util.List) {
                        mvIds = new java.util.ArrayList<>();
                        java.util.List l = (java.util.List) payload.get("mvIds");
                        for (Object o : l) {
                            try { mvIds.add(Integer.valueOf(String.valueOf(o))); } catch(Exception ex) {}
                        }
                    }
                    if (payload.get("mvId") != null) { try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ex) { mvId = null; } }
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String sIsbns = request.getParameter("isbns");
                String sIsbns13 = request.getParameter("isbns13");
                String sMvIds = request.getParameter("mvIds");
                String sMvId = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length() > 0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length() > 0) isbn13 = pIsbn13.trim();
                if (sIsbns != null && sIsbns.trim().length() > 0) {
                    isbns = new java.util.ArrayList<>();
                    for (String v : sIsbns.split(",")) if (v.trim().length()>0) isbns.add(v.trim());
                }
                if (sIsbns13 != null && sIsbns13.trim().length() > 0) {
                    isbns13 = new java.util.ArrayList<>();
                    for (String v : sIsbns13.split(",")) if (v.trim().length()>0) isbns13.add(v.trim());
                }
                if (sMvIds != null && sMvIds.trim().length() > 0) {
                    mvIds = new java.util.ArrayList<>();
                    for (String v : sMvIds.split(",")) { try { mvIds.add(Integer.valueOf(v.trim())); } catch(Exception ex) {} }
                }
                if (sMvId != null && sMvId.trim().length()>0) { try { mvId = Integer.valueOf(sMvId.trim()); } catch(Exception ex) { mvId = null; } }
            }

            // If plural arrays provided, return a map keyed by identifier with count/user flags
            Map<String,Object> dataMap = new HashMap<>();
            com.mn.cm.model.User u = (com.mn.cm.model.User) request.getSession().getAttribute("USER_SESSION");
            String userId = (u != null) ? String.valueOf(u.getId()) : null;

            if (isbns != null && !isbns.isEmpty()) {
                for (String s : isbns) {
                    try {
                        long cnt = wishDAO.selectWishCount(s, null);
                        Map<String,Object> entry = new HashMap<>();
                        entry.put("count", cnt);
                        if (userId != null) {
                            long has = wishDAO.selectUserWishCount(userId, s, null);
                            entry.put("userHasWish", has > 0);
                            entry.put("userWishCount", has);
                        }
                        dataMap.put(s, entry);
                    } catch (Exception ex) { logger.debug("[WISH COUNT] failed for isbn {}: {}", s, ex.getMessage()); dataMap.put(s, java.util.Collections.singletonMap("count", 0)); }
                }
                result.put("status","OK"); result.put("data", dataMap); return result;
            }

            if (isbns13 != null && !isbns13.isEmpty()) {
                for (String s : isbns13) {
                    try {
                        long cnt = wishDAO.selectWishCount(null, s);
                        Map<String,Object> entry = new HashMap<>();
                        entry.put("count", cnt);
                        if (userId != null) {
                            long has = wishDAO.selectUserWishCount(userId, null, s);
                            entry.put("userHasWish", has > 0);
                            entry.put("userWishCount", has);
                        }
                        dataMap.put(s, entry);
                    } catch (Exception ex) { logger.debug("[WISH COUNT] failed for isbn13 {}: {}", s, ex.getMessage()); dataMap.put(s, java.util.Collections.singletonMap("count", 0)); }
                }
                result.put("status","OK"); result.put("data", dataMap); return result;
            }

            if (mvIds != null && !mvIds.isEmpty()) {
                for (Integer m : mvIds) {
                    try {
                        long cnt = (m != null) ? wishDAO.selectMovieWishCount(m) : 0L;
                        Map<String,Object> entry = new HashMap<>();
                        entry.put("count", cnt);
                        if (userId != null && m != null) {
                            long has = wishDAO.selectUserMovieWishCount(userId, m);
                            entry.put("userHasWish", has > 0);
                            entry.put("userWishCount", has);
                        }
                        dataMap.put(String.valueOf(m), entry);
                    } catch (Exception ex) { logger.debug("[WISH COUNT] failed for mvId {}: {}", m, ex.getMessage()); dataMap.put(String.valueOf(m), java.util.Collections.singletonMap("count", 0)); }
                }
                result.put("status","OK"); result.put("data", dataMap); return result;
            }

            // Fallback: single-item behavior (preserve original responses)
            if (mvId != null) {
                long cnt = wishDAO.selectMovieWishCount(mvId);
                result.put("status","OK"); result.put("data", java.util.Collections.singletonMap("count", cnt));
                return result;
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }
            long cnt = wishDAO.selectWishCount(isbn, isbn13);

            result.put("status","OK"); result.put("data", java.util.Collections.singletonMap("count", cnt));

            if (u != null) {
                long has = wishDAO.selectUserWishCount(String.valueOf(u.getId()), isbn, isbn13);
                result.put("userHasWish", has > 0);
                result.put("userWishCount", has);
            }

            return result;
        } catch (Exception ex) {
            logger.error("[WISH COUNT] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/status", produces = "application/json")
    @ResponseBody
    public Map<String,Object> status(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            java.util.List<String> isbns = new java.util.ArrayList<>();
            java.util.List<String> isbns13 = new java.util.ArrayList<>();
            java.util.List<Integer> mvIds = new java.util.ArrayList<>();
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbns") instanceof java.util.List) isbns = (java.util.List<String>) payload.get("isbns");
                    if (payload.get("isbns13") instanceof java.util.List) isbns13 = (java.util.List<String>) payload.get("isbns13");
                    if (payload.get("mvIds") instanceof java.util.List) {
                        java.util.List l = (java.util.List) payload.get("mvIds");
                        for (Object o : l) {
                            try { mvIds.add(Integer.valueOf(String.valueOf(o))); } catch(Exception ex) {}
                        }
                    }
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String sIsbns = request.getParameter("isbns");
                String sIsbns13 = request.getParameter("isbns13");
                String sMvIds = request.getParameter("mvIds");
                if (sIsbns != null && sIsbns.trim().length() > 0) {
                    for (String v : sIsbns.split(",")) if (v.trim().length()>0) isbns.add(v.trim());
                }
                if (sIsbns13 != null && sIsbns13.trim().length() > 0) {
                    for (String v : sIsbns13.split(",")) if (v.trim().length()>0) isbns13.add(v.trim());
                }
                if (sMvIds != null && sMvIds.trim().length() > 0) {
                    for (String v : sMvIds.split(",")) { try { mvIds.add(Integer.valueOf(v.trim())); } catch(Exception ex) {} }
                }
            }

            Map<String,Object> map = new HashMap<>();
            // check isbns
            for (String s : isbns) {
                try {
                    long cnt = wishDAO.selectUserWishCount(userId, s, null);
                    map.put(s, cnt > 0);
                } catch (Exception ex) { logger.debug("[WISH STATUS] check failed for {}: {}", s, ex.getMessage()); map.put(s, false); }
            }
            // check isbns13
            for (String s : isbns13) {
                try {
                    long cnt = wishDAO.selectUserWishCount(userId, null, s);
                    map.put(s, cnt > 0);
                } catch (Exception ex) { logger.debug("[WISH STATUS] check failed for isbn13 {}: {}", s, ex.getMessage()); map.put(s, false); }
            }
            // check mvIds
            for (Integer m : mvIds) {
                try {
                    long cnt = wishDAO.selectUserMovieWishCount(userId, m);
                    map.put(String.valueOf(m), cnt > 0);
                } catch (Exception ex) { logger.debug("[WISH STATUS] check failed for mvId {}: {}", m, ex.getMessage()); map.put(String.valueOf(m), false); }
            }

            result.put("status","OK"); result.put("data", map); return result;
        } catch (Exception ex) {
            logger.error("[WISH STATUS] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    // New: return logged-in user's wishlist items (for /wish/my)
    @RequestMapping(value = "/my", method = {org.springframework.web.bind.annotation.RequestMethod.GET, org.springframework.web.bind.annotation.RequestMethod.POST}, produces = "application/json")
    @ResponseBody
    public Map<String,Object> myWishes(HttpSession session, HttpServletRequest request, @org.springframework.web.bind.annotation.RequestParam(value = "offset", required = false) Integer offset, @org.springframework.web.bind.annotation.RequestParam(value = "limit", required = false) Integer limit) {
        Map<String,Object> result = new HashMap<>();
        try {
            logger.info("[WISH MY] invoked via {} from {}", request.getMethod(), request.getRemoteAddr());
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());
            if (offset == null) offset = 0; if (limit == null) limit = 200;
            java.util.List<java.util.Map<String,Object>> rows = wishDAO.selectWishesByUser(userId, offset, limit);
            // normalize REG_DT like review controller
            try {
                java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                for (java.util.Map<String,Object> r : rows) {
                    if (r == null) continue;
                    Object reg = r.get("REG_DT"); if (reg == null) reg = r.get("regDt"); if (reg != null) {
                        try {
                            if (reg instanceof java.time.LocalDateTime) { r.put("REG_DT", ((java.time.LocalDateTime)reg).format(dtf)); }
                            else if (reg instanceof java.sql.Timestamp) { java.sql.Timestamp ts = (java.sql.Timestamp) reg; r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(ts.getTime()))); }
                            else if (reg instanceof java.util.Date) { r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format((java.util.Date)reg)); }
                            else if (reg instanceof String) { r.put("REG_DT", String.valueOf(reg)); }
                            else { r.put("REG_DT", String.valueOf(reg)); }
                        } catch (Exception ex) { try { r.put("REG_DT", String.valueOf(reg)); } catch(Exception ignore) {} }
                    }
                }
            } catch (Exception ex) { /* ignore */ }

            result.put("status","OK"); result.put("data", rows); return result;
        } catch (Exception ex) {
            logger.error("[WISH MY] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

}
