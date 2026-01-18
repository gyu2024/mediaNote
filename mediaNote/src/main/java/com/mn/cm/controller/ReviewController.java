package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.Map;
import java.util.HashMap;
import java.util.stream.Collectors;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.mn.cm.dao.ReviewDAO;
import com.mn.cm.model.User;

@Controller
@RequestMapping("/review")
public class ReviewController {

    @Autowired
    private ReviewDAO reviewDAO;

    private static final Logger logger = LoggerFactory.getLogger(ReviewController.class);

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Single robust save endpoint: accepts JSON bodies or form-encoded posts.
     */
    @PostMapping(value = "/save", produces = "application/json")
    @ResponseBody
    public Map<String, Object> saveReviewGeneric(HttpServletRequest request, HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        try {
            User u = (User) session.getAttribute("USER_SESSION");
            if (u == null) {
                result.put("status", "ERR");
                result.put("message", "NOT_LOGGED_IN");
                return result;
            }

            String userId = String.valueOf(u.getId());

            // Build a payload map from JSON body if present, otherwise from request parameters
            Map<String, Object> payload = new HashMap<>();
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    parsedJson = true;
                }
            } catch (Exception ex) {
                logger.debug("[SAVE_REVIEW] failed to parse JSON body: {}", ex.getMessage());
            }

            if (!parsedJson) {
                // read parameters (first value of each parameter)
                Map<String, String[]> params = request.getParameterMap();
                payload = params.entrySet().stream().collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().length > 0 ? e.getValue()[0] : null));
                logger.debug("[SAVE_REVIEW] parsed form params into payload: {}", payload);
            }

            // Accept multiple possible keys for ISBN/item id
            String isbn = String.valueOf(payload.get("isbn"));
            String isbn13 = String.valueOf(payload.get("isbn13"));


            // additional payload values
            Double rating = null;
            if (payload.get("rating") != null) {
                try { rating = Double.valueOf(String.valueOf(payload.get("rating"))); } catch (Exception e) { rating = null; }
            }
            String comnet = payload.get("comment") != null ? String.valueOf(payload.get("comment")) : (payload.get("comnet") != null ? String.valueOf(payload.get("comnet")) : null);
            String reviewText = payload.get("text") != null ? String.valueOf(payload.get("text")) : null;

            logger.info("[SAVE_REVIEW] request - parsedJson:{}, user:{}, isbn:{}, rating:{}, commentPresent:{}, textPresent:{}",
                    parsedJson, userId, isbn, rating, (comnet!=null), (reviewText!=null));

            // Persist review: pass both isbn and isbn13 so mapper columns are set correctly
            reviewDAO.insertOrUpdateReview(userId, isbn, isbn13, rating, comnet, reviewText);

            result.put("status", "OK");
            return result;
        } catch (Exception ex) {
            logger.error("[SAVE_REVIEW] server error", ex);
            result.put("status", "ERR");
            result.put("message", ex.getMessage());
            return result;
        }
    }

    @PostMapping(value = "/status", produces = "application/json")
    @ResponseBody
    public Map<String, Object> status(HttpServletRequest request, HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) {
                result.put("status", "ERR");
                result.put("message", "NOT_LOGGED_IN");
                return result;
            }
            String userId = String.valueOf(u.getId());

            // parse request body or params
            java.util.List<String> isbns = new java.util.ArrayList<>();
            java.util.List<String> isbns13 = new java.util.ArrayList<>();
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbns") instanceof java.util.List) isbns = (java.util.List<String>) payload.get("isbns");
                    if (payload.get("isbns13") instanceof java.util.List) isbns13 = (java.util.List<String>) payload.get("isbns13");
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                // try request parameters: comma separated
                String sIsbns = request.getParameter("isbns");
                String sIsbns13 = request.getParameter("isbns13");
                if (sIsbns != null && sIsbns.trim().length() > 0) {
                    for (String v : sIsbns.split(",")) if (v.trim().length()>0) isbns.add(v.trim());
                }
                if (sIsbns13 != null && sIsbns13.trim().length() > 0) {
                    for (String v : sIsbns13.split(",")) if (v.trim().length()>0) isbns13.add(v.trim());
                }
            }
            logger.debug("[STATUS] request isbns={} isbns13={}", isbns, isbns13);

            java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectStatuses(userId, isbns, isbns13);
            // build map keyed by ISBN or ISBN13 -> status
            Map<String,Object> map = new HashMap<>();
            for (Map<String,Object> r : rows) {
                String isbnVal = r.get("ISBN") != null ? String.valueOf(r.get("ISBN")) : null;
                String isbn13Val = r.get("ISBN13") != null ? String.valueOf(r.get("ISBN13")) : null;
                Map<String,Object> st = new HashMap<>();
                st.put("readYn", r.get("READ_YN"));
                st.put("rating", r.get("RATING"));
                st.put("comnet", r.get("COMNET"));
                st.put("reviewText", r.get("REVIEW_TEXT"));
                // map under both identifiers so client can look up by either
                if (isbnVal != null && !isbnVal.trim().isEmpty()) map.put(isbnVal, st);
                if (isbn13Val != null && !isbn13Val.trim().isEmpty() && !isbn13Val.equals(isbnVal)) map.put(isbn13Val, st);
            }
            logger.debug("[STATUS] returning map keys={}", map.keySet());
             result.put("status", "OK");
             result.put("data", map);
             return result;
        } catch (Exception ex) {
            logger.error("[STATUS] error", ex);
            result.put("status", "ERR");
            result.put("message", ex.getMessage());
            return result;
        }
    }

    @PostMapping(value = "/read", produces = "application/json")
    @ResponseBody
    public Map<String,Object> setRead(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) {
                result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result;
            }
            String userId = String.valueOf(u.getId());
            String isbn = null;
            String isbn13 = null;
            String readYn = "Y";
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("readYn") != null) readYn = String.valueOf(payload.get("readYn")).toUpperCase();
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pRead = request.getParameter("readYn");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pRead != null && pRead.trim().length()>0) readYn = pRead.trim().toUpperCase();
            }
            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            // If attempting to unset read (readYn == 'N'), disallow when a rating/comment/review exists
            if ("N".equalsIgnoreCase(readYn)) {
                java.util.List<String> isbns = new java.util.ArrayList<>();
                java.util.List<String> isbns13 = new java.util.ArrayList<>();
                if (isbn != null && isbn.trim().length() > 0) isbns.add(isbn.trim());
                if (isbn13 != null && isbn13.trim().length() > 0) isbns13.add(isbn13.trim());
                java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectStatuses(userId, isbns, isbns13);
                if (rows != null && rows.size() > 0) {
                    for (Map<String,Object> r : rows) {
                        Object ratingObj = r.get("RATING");
                        Object comnetObj = r.get("COMNET");
                        Object reviewTextObj = r.get("REVIEW_TEXT");
                        boolean hasRatingOrComment = (ratingObj != null) || (comnetObj != null && String.valueOf(comnetObj).trim().length() > 0) || (reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0);
                        if (hasRatingOrComment) {
                            // refuse to unset read when review/score exists
                            result.put("status","ERR");
                            result.put("message","CANNOT_UNSET_READ_HAS_RATING");
                            return result;
                        }
                    }
                }
            }

            reviewDAO.setReadStatus(userId, isbn, isbn13, ("Y".equals(readYn) ? "Y" : "N"));
            result.put("status","OK"); return result;
        } catch (Exception ex) {
            logger.error("[READ] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/delete", produces = "application/json")
    @ResponseBody
    public Map<String,Object> deleteReview(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            reviewDAO.deleteReview(userId, isbn, isbn13);
            result.put("status","OK"); return result;
        } catch (Exception ex) {
            logger.error("[DELETE] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

    // helper: rough ISBN heuristic (10 or 13 digits, optionally with hyphens or an ending X)
    private boolean isLikelyIsbn(String s) {
        if (s == null) return false;
        String t = s.replaceAll("-", "").replaceAll("\\s+", "");
        if (t.length() == 10) return t.matches("^[0-9]{9}[0-9Xx]$");
        if (t.length() == 13) return t.matches("^[0-9]{13}$");
        return false;
    }
}