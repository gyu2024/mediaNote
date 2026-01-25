package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMethod;

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
import com.mn.cm.dao.MovieReviewDAO;
import com.mn.cm.model.User;

@Controller
@RequestMapping("/review")
public class ReviewController {

    @Autowired
    private ReviewDAO reviewDAO;

    @Autowired
    private MovieReviewDAO movieReviewDAO;

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
            String isbn = payload.get("isbn") != null ? String.valueOf(payload.get("isbn")) : null;
            String isbn13 = payload.get("isbn13") != null ? String.valueOf(payload.get("isbn13")) : null;

            // Detect movie id (support mvId / movieId / itemMovieId)
            Integer mvId = null;
            try {
                Object mobj = payload.get("mvId");
                if (mobj == null) mobj = payload.get("movieId");
                if (mobj == null) mobj = payload.get("itemMovieId");
                if (mobj == null) mobj = payload.get("itemId");
                if (mobj != null) {
                    String ms = String.valueOf(mobj);
                    if (ms != null && ms.trim().length() > 0) mvId = Integer.valueOf(ms.trim());
                }
            } catch (Exception ignore) { mvId = null; }

            // additional payload values
            Double rating = null;
            if (payload.get("rating") != null) {
                try { rating = Double.valueOf(String.valueOf(payload.get("rating"))); } catch (Exception e) { rating = null; }
            }
            String cmnt = payload.get("comment") != null ? String.valueOf(payload.get("comment")) : (payload.get("cmnt") != null ? String.valueOf(payload.get("cmnt")) : null);
            String reviewText = payload.get("text") != null ? String.valueOf(payload.get("text")) : null;

            logger.info("[SAVE_REVIEW] request - parsedJson:{}, user:{}, isbn:{}, mvId:{}, rating:{}, cmntPresent:{}, textPresent:{}",
                    parsedJson, userId, isbn, mvId, rating, (cmnt!=null), (reviewText!=null));

            // If this is a movie review (mvId present), route to MovieReviewDAO
            if (mvId != null) {
                movieReviewDAO.insertOrUpdateReview(userId, mvId, rating, cmnt, reviewText);
                result.put("status", "OK");
                return result;
            }

            // Persist review: pass both isbn and isbn13 so mapper columns are set correctly (book flow)
            reviewDAO.insertOrUpdateReview(userId, isbn, isbn13, rating, cmnt, reviewText);

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
            // Parse request body or params BEFORE enforcing login so we can support public movie-summary requests
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
                    // movie ids (mvIds)
                    if (payload.get("mvIds") instanceof java.util.List) {
                        java.util.List l = (java.util.List) payload.get("mvIds");
                        for (Object o : l) try { if (o!=null) mvIds.add(Integer.valueOf(String.valueOf(o))); } catch(Exception ignore) {}
                    }
                    // single mvId
                    if (payload.get("mvId") != null) {
                        try { mvIds.add(Integer.valueOf(String.valueOf(payload.get("mvId")))); } catch(Exception ignore) {}
                    }
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                // try request parameters: comma separated
                String sIsbns = request.getParameter("isbns");
                String sIsbns13 = request.getParameter("isbns13");
                String sMvIds = request.getParameter("mvIds");
                String sMvId = request.getParameter("mvId");
                if (sIsbns != null && sIsbns.trim().length() > 0) {
                    for (String v : sIsbns.split(",")) if (v.trim().length()>0) isbns.add(v.trim());
                }
                if (sIsbns13 != null && sIsbns13.trim().length() > 0) {
                    for (String v : sIsbns13.split(",")) if (v.trim().length()>0) isbns13.add(v.trim());
                }
                if (sMvIds != null && sMvIds.trim().length() > 0) {
                    for (String v : sMvIds.split(",")) try { if (v.trim().length()>0) mvIds.add(Integer.valueOf(v.trim())); } catch(Exception ignore) {}
                }
                if (sMvId != null && sMvId.trim().length() > 0) {
                    try { mvIds.add(Integer.valueOf(sMvId.trim())); } catch(Exception ignore) {}
                }
            }
            logger.debug("[STATUS] request isbns={} isbns13={} mvIds={}", isbns, isbns13, mvIds);

            // Retrieve user session if present (but DO NOT require login for movie-summary requests)
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            String userId = null;
            if (u != null) userId = String.valueOf(u.getId());

            // If mvIds provided -> movie flow. Allow unauthenticated callers to receive aggregate summary data.
            if (mvIds != null && mvIds.size() > 0) {
                Map<String,Object> map = new HashMap<>();

                // If user is logged in, fetch per-user statuses so client can show read/review flags
                if (userId != null) {
                    try {
                        java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                        for (Map<String,Object> r : rows) {
                            Object mvObj = r.get("MV_ID") != null ? r.get("MV_ID") : r.get("mv_id");
                            String mvKey = mvObj != null ? String.valueOf(mvObj) : null;
                            Map<String,Object> st = new HashMap<>();
                            // core fields (preserve original values)
                            st.put("readYn", r.get("READ_YN"));
                            st.put("rating", r.get("RATING"));
                            st.put("cmnt", r.get("CMNT"));
                            st.put("reviewText", r.get("REVIEW_TEXT"));
                            // Explicit, normalized booleans to make client checks deterministic
                            boolean hasReview = false;
                            try {
                                Object ratingObj = r.get("RATING");
                                Object cmntObj = r.get("CMNT");
                                Object reviewTextObj = r.get("REVIEW_TEXT");
                                if (ratingObj != null) hasReview = true;
                                if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                            } catch (Exception ignore) { }
                            st.put("hasUserReview", hasReview);
                            // userRead normalized boolean
                            boolean userRead = false;
                            try {
                                Object ryn = r.get("READ_YN");
                                if (ryn != null) {
                                    String s = String.valueOf(ryn).trim();
                                    if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) userRead = true;
                                }
                            } catch (Exception ignore) {}
                            st.put("userRead", userRead);
                                 if (mvKey != null && mvKey.trim().length()>0) map.put(mvKey, st);
                        }
                    } catch (Exception ex) {
                        logger.warn("[STATUS] failed to fetch per-user movie statuses: {}", ex.getMessage());
                    }
                }

                // ALSO include aggregate summary (avg rating, counts) for each requested mvId so clients can display averages
                try {
                    // batch-fetch summaries for all requested mvIds
                    java.util.List<java.util.Map<String,Object>> summaryRows = movieReviewDAO.selectMovieSummaries(mvIds);
                    if (summaryRows != null) {
                        for (java.util.Map<String,Object> srow : summaryRows) {
                            try {
                                Object mvObj = srow.get("MV_ID") != null ? srow.get("MV_ID") : srow.get("mv_id");
                                if (mvObj == null) continue;
                                String key = String.valueOf(mvObj);
                                Object avg = srow.get("AVG_RATING") != null ? srow.get("AVG_RATING") : srow.get("avg_rating");
                                Object rCnt = srow.get("RATING_CNT") != null ? srow.get("RATING_CNT") : srow.get("rating_cnt");
                                Object readCnt = srow.get("READ_CNT") != null ? srow.get("READ_CNT") : srow.get("read_cnt");
                                Object likeCnt = srow.get("LIKE_CNT") != null ? srow.get("LIKE_CNT") : srow.get("like_cnt");
                                Object reviewWithTextCnt = srow.get("REVIEW_WITH_TEXT_CNT") != null ? srow.get("REVIEW_WITH_TEXT_CNT") : srow.get("review_with_text_cnt");
                                Object cmntCnt = srow.get("CMNT_CNT") != null ? srow.get("CMNT_CNT") : srow.get("cmnt_cnt");
                                Object reviewTextCnt = srow.get("REVIEW_TEXT_CNT") != null ? srow.get("REVIEW_TEXT_CNT") : srow.get("review_text_cnt");
                                // compute reviewCnt from reviewWithTextCnt if available
                                Object reviewCnt = reviewWithTextCnt != null ? reviewWithTextCnt : 0;
                                Map<String,Object> existing = (Map<String,Object>) map.get(key);
                                if (existing == null) existing = new HashMap<>();
                                existing.put("avgRating", avg != null ? avg : null);
                                existing.put("ratingCount", rCnt != null ? rCnt : 0);
                                existing.put("readCount", readCnt != null ? readCnt : 0);
                                existing.put("cmntCount", cmntCnt != null ? cmntCnt : 0);
                                existing.put("reviewTextCount", reviewTextCnt != null ? reviewTextCnt : 0);
                                // prefer explicit review-with-text count as likeCount if present
                                existing.put("likeCount", reviewWithTextCnt != null ? reviewWithTextCnt : (likeCnt != null ? likeCnt : 0));
                                existing.put("reviewCount", reviewCnt != null ? reviewCnt : 0);
                                map.put(key, existing);
                            } catch (Exception inner) { logger.warn("[STATUS] failed to merge summary row: {}", inner.getMessage()); }
                        }
                    }
                } catch (Exception ex) {
                    logger.warn("[STATUS] movie summary aggregation failed: {}", ex.getMessage());
                }

                result.put("status", "OK"); result.put("data", map); return result;
            }

            // For non-movie (book) flow require login as before
            if (userId == null) {
                result.put("status", "ERR");
                result.put("message", "NOT_LOGGED_IN");
                return result;
            }

            // book flow (existing)
            java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectStatuses(userId, isbns, isbns13);
            // build map keyed by ISBN or ISBN13 -> status
            Map<String,Object> map = new HashMap<>();
            for (Map<String,Object> r : rows) {
                String isbnVal = r.get("ISBN") != null ? String.valueOf(r.get("ISBN")) : null;
                String isbn13Val = r.get("ISBN13") != null ? String.valueOf(r.get("ISBN13")) : null;
                Map<String,Object> st = new HashMap<>();
                st.put("readYn", r.get("READ_YN"));
                st.put("rating", r.get("RATING"));
                st.put("cmnt", r.get("CMNT"));
                st.put("reviewText", r.get("REVIEW_TEXT"));
                // map under both identifiers so client can look up by either
                if (isbnVal != null && !isbnVal.trim().isEmpty()) map.put(isbnVal, st);
                if (isbn13Val != null && isbn13Val.trim().length() > 0 && !isbn13Val.equals(isbnVal)) map.put(isbn13Val, st);
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
            Integer mvId = null;
            String readYn = "Y";
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("readYn") != null) readYn = String.valueOf(payload.get("readYn")).toUpperCase();
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch (Exception ignore) {}
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pRead = request.getParameter("readYn");
                String pMv = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pRead != null && pRead.trim().length()>0) readYn = pRead.trim().toUpperCase();
                if (pMv != null && pMv.trim().length()>0) try { mvId = Integer.valueOf(pMv.trim()); } catch(Exception ignore) {}
            }
            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0) && mvId==null) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN_OR_MVID"); return result;
            }

            // If attempting to unset read (readYn == 'N'), disallow when a rating/comment/review exists
            if ("N".equalsIgnoreCase(readYn)) {
                if (mvId != null) {
                    java.util.List<Integer> mvIds = new java.util.ArrayList<>(); mvIds.add(mvId);
                    java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                    if (rows != null && rows.size() > 0) {
                        for (Map<String,Object> r : rows) {
                            Object ratingObj = r.get("RATING");
                            Object comnetObj = r.get("CMNT");
                            Object reviewTextObj = r.get("REVIEW_TEXT");
                            boolean hasRatingOrComment = (ratingObj != null) || (comnetObj != null && String.valueOf(comnetObj).trim().length() > 0) || (reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0);
                            if (hasRatingOrComment) {
                                result.put("status","ERR"); result.put("message","CANNOT_UNSET_READ_HAS_RATING"); return result;
                            }
                        }
                    }
                } else {
                    java.util.List<String> isbns = new java.util.ArrayList<>();
                    java.util.List<String> isbns13 = new java.util.ArrayList<>();
                    if (isbn != null && isbn.trim().length() > 0) isbns.add(isbn.trim());
                    if (isbn13 != null && isbn13.trim().length() > 0) isbns13.add(isbn13.trim());
                    java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectStatuses(userId, isbns, isbns13);
                    if (rows != null && rows.size() > 0) {
                        for (Map<String,Object> r : rows) {
                            Object ratingObj = r.get("RATING");
                            Object comnetObj = r.get("CMNT");
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
            }

            if (mvId != null) {
                movieReviewDAO.setReadStatus(userId, mvId, ("Y".equals(readYn) ? "Y" : "N"));
                result.put("status","OK"); return result;
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

            String isbn = null; String isbn13 = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ignore) {}
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pMv = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pMv != null && pMv.trim().length()>0) try { mvId = Integer.valueOf(pMv.trim()); } catch(Exception ignore) {}
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0) && mvId==null) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN_OR_MVID"); return result;
            }

            if (mvId != null) {
                movieReviewDAO.deleteReview(userId, mvId);
                result.put("status","OK"); return result;
            }

            reviewDAO.deleteReview(userId, isbn, isbn13);
            result.put("status","OK"); return result;
        } catch (Exception ex) {
            logger.error("[DELETE] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/vote", produces = "application/json")
    @ResponseBody
    public Map<String,Object> voteReview(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());
            String isbn = null; String isbn13 = null; String regDt = null; String action = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("regDt") != null) regDt = String.valueOf(payload.get("regDt"));
                    if (payload.get("action") != null) action = String.valueOf(payload.get("action"));
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ignore) {}
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                if (request.getParameter("isbn") != null) isbn = request.getParameter("isbn");
                if (request.getParameter("isbn13") != null) isbn13 = request.getParameter("isbn13");
                if (request.getParameter("regDt") != null) regDt = request.getParameter("regDt");
                if (request.getParameter("action") != null) action = request.getParameter("action");
                if (request.getParameter("mvId") != null) try { mvId = Integer.valueOf(request.getParameter("mvId")); } catch(Exception ignore) {}
            }
            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0) && mvId==null) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN_OR_MVID"); return result; }
            if (regDt == null || regDt.trim().length() == 0) { result.put("status","ERR"); result.put("message","MISSING_REGDT"); return result; }
            if (!"like".equals(action) && !"dislike".equals(action)) { result.put("status","ERR"); result.put("message","INVALID_ACTION"); return result; }

            // server-side: check existing reaction for this user+review to prevent duplicate same-action votes
            try {
                if (mvId != null) {
                    Integer existing = movieReviewDAO.selectUserReaction(userId, mvId, regDt);
                    if (existing != null) {
                        String existingAction = (existing == 0) ? "like" : (existing == 1) ? "dislike" : null;
                        if (existingAction != null && existingAction.equals(action)) {
                            // Toggle off: user clicked same action again -> delete their reaction
                            try {
                                movieReviewDAO.deleteUserReaction(userId, mvId, regDt);
                                java.util.Map<String,Object> rowAfter = movieReviewDAO.selectReviewByKey(mvId, regDt);
                                Map<String,Object> dataAfter = new HashMap<>();
                                if (rowAfter != null) {
                                    dataAfter.put("lkCnt", rowAfter.get("LK_CNT") != null ? rowAfter.get("LK_CNT") : rowAfter.get("lk_cnt") );
                                    dataAfter.put("dslkCnt", rowAfter.get("DSLK_CNT") != null ? rowAfter.get("DSLK_CNT") : rowAfter.get("dslk_cnt") );
                                }
                                result.put("status","OK"); result.put("data", dataAfter); return result;
                            } catch (Exception ex) {
                                logger.error("[VOTE] toggle-off delete failed", ex);
                                result.put("status","ERR"); result.put("message","DELETE_FAILED"); return result;
                            }
                        }
                    }
                }
            } catch (Exception ex) {
                // ignore and proceed to allow DAO to handle idempotency if needed
                logger.info("[VOTE] existing reaction check failed: {}", ex.getMessage());
            }

            if (mvId != null) {
                movieReviewDAO.voteReview(userId, mvId, regDt, action);
                java.util.Map<String,Object> row = movieReviewDAO.selectReviewByKey(mvId, regDt);
                Map<String,Object> data = new HashMap<>();
                if (row != null) {
                    data.put("lkCnt", row.get("LK_CNT") != null ? row.get("LK_CNT") : row.get("lk_cnt") );
                    data.put("dslkCnt", row.get("DSLK_CNT") != null ? row.get("DSLK_CNT") : row.get("dslk_cnt") );
                }
                result.put("status","OK"); result.put("data", data); return result;
            }

            // Pass userId so DAO can record per-user reactions in MN_BK_LIKE
            reviewDAO.voteReview(userId, isbn, isbn13, regDt, action);
            java.util.Map<String,Object> row = reviewDAO.selectReviewByKey(isbn, isbn13, regDt);
            Map<String,Object> data = new HashMap<>();
            if (row != null) {
                data.put("lkCnt", row.get("LK_CNT") != null ? row.get("LK_CNT") : row.get("lk_cnt") );
                data.put("dslkCnt", row.get("DSLK_CNT") != null ? row.get("DSLK_CNT") : row.get("dslk_cnt") );
            }
            result.put("status","OK"); result.put("data", data); return result;
        } catch (Exception ex) {
            logger.error("[VOTE] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    // Public endpoint: list reviews for a book (recent first)
    @PostMapping(value = "/list", produces = "application/json")
    @ResponseBody
    public Map<String,Object> listReviews(HttpServletRequest request) {
        Map<String,Object> result = new HashMap<>();
        try {
            String isbn = null; String isbn13 = null; Integer limit = 10; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("limit") != null) {
                        try { limit = Integer.valueOf(String.valueOf(payload.get("limit"))); } catch(Exception e){ }
                    }
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ignore) {}
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pLimit = request.getParameter("limit");
                String pMv = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pLimit != null) {
                    try { limit = Integer.valueOf(pLimit); } catch(Exception e) {}
                }
                if (pMv != null && pMv.trim().length()>0) try { mvId = Integer.valueOf(pMv.trim()); } catch(Exception ignore) {}
            }

            if (mvId != null) {
                java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectReviews(mvId, limit);
                try {
                    java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                    for (java.util.Map<String,Object> r : rows) {
                        if (r == null) continue;
                        Object reg = r.get("REG_DT");
                        if (reg == null) reg = r.get("reg_dt");
                        if (reg != null) {
                            try {
                                if (reg instanceof java.time.LocalDateTime) {
                                    r.put("REG_DT", ((java.time.LocalDateTime)reg).format(dtf));
                                } else if (reg instanceof java.sql.Timestamp) {
                                    java.sql.Timestamp ts = (java.sql.Timestamp) reg;
                                    r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(ts.getTime())));
                                } else if (reg instanceof java.util.Date) {
                                    r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format((java.util.Date)reg));
                                } else if (reg instanceof String) {
                                    r.put("REG_DT", String.valueOf(reg));
                                } else {
                                    r.put("REG_DT", String.valueOf(reg));
                                }
                            } catch (Exception ex) {
                                try { r.put("REG_DT", String.valueOf(reg)); } catch (Exception ignore) {}
                            }
                        }
                    }
                } catch (Exception ex) { }

                result.put("status","OK"); result.put("data", rows); return result;
            }

            java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectReviews(isbn, isbn13, limit);

            // Convert database datetime types to strings (avoid Jackson LocalDateTime serialization issues)
            try {
                java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                for (java.util.Map<String,Object> r : rows) {
                    if (r == null) continue;
                    Object reg = r.get("REG_DT");
                    if (reg == null) reg = r.get("reg_dt");
                    if (reg != null) {
                        try {
                            if (reg instanceof java.time.LocalDateTime) {
                                r.put("REG_DT", ((java.time.LocalDateTime)reg).format(dtf));
                            } else if (reg instanceof java.sql.Timestamp) {
                                java.sql.Timestamp ts = (java.sql.Timestamp) reg;
                                r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(ts.getTime())));
                            } else if (reg instanceof java.util.Date) {
                                r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format((java.util.Date)reg));
                            } else if (reg instanceof String) {
                                // leave as-is
                                r.put("REG_DT", String.valueOf(reg));
                            } else {
                                // fallback to toString
                                r.put("REG_DT", String.valueOf(reg));
                            }
                        } catch (Exception ex) {
                            // ensure we don't break the whole response
                            try { r.put("REG_DT", String.valueOf(reg)); } catch (Exception ignore) {}
                        }
                    }
                }
            } catch (Exception ex) {
                // ignore; we'll still return rows even if formatting fails
            }

            result.put("status","OK");
            result.put("data", rows);
            return result;
        } catch (Exception ex) {
            logger.error("[LIST] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

    // New: book-level summary endpoint (public)
    @PostMapping(value = "/summary", produces = "application/json")
    @ResponseBody
    public Map<String,Object> bookSummary(HttpServletRequest request) {
        Map<String,Object> result = new HashMap<>();
        // Quick stdout probe so we can see a console line even when logging is filtered
        System.out.println("[SUMMARY-STDOUT] invoked: " + request.getRequestURI() + " from " + request.getRemoteAddr());
        // Log immediately on entry so we know the endpoint was invoked
        logger.info("[SUMMARY] endpoint invoked: uri={}, remoteAddr={}, query={}", request.getRequestURI(), request.getRemoteAddr(), request.getQueryString());
        try {
            String isbn = null; String isbn13 = null; Integer mvId = null;
            String contentType = request.getContentType();
            logger.info("[SUMMARY] contentType={}", contentType);
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    // support single-string keys
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ignore) {}
                    // also support arrays (isbns / isbns13) where client might send arrays
                    try {
                        if ((isbn == null || isbn.trim().length() == 0) && payload.get("isbns") instanceof java.util.List) {
                            java.util.List l = (java.util.List) payload.get("isbns"); if (l.size()>0) isbn = String.valueOf(l.get(0));
                        }
                    } catch (Exception ignore) {}
                    try {
                        if ((isbn13 == null || isbn13.trim().length() == 0) && payload.get("isbns13") instanceof java.util.List) {
                            java.util.List l2 = (java.util.List) payload.get("isbns13"); if (l2.size()>0) isbn13 = String.valueOf(l2.get(0));
                        }
                    } catch (Exception ignore) {}
                    parsedJson = true;
                    logger.info("[SUMMARY] parsed JSON payload: isbn={}, isbn13={}, mvId={}", isbn, isbn13, mvId);
                }
            } catch (Exception ex) { logger.info("[SUMMARY] json parse attempt failed: {}", ex.getMessage()); }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                String pMv = request.getParameter("mvId");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
                if (pMv != null && pMv.trim().length()>0) try { mvId = Integer.valueOf(pMv.trim()); } catch(Exception ignore) {}
                logger.info("[SUMMARY] parsed params: isbn={}, isbn13={}, mvId={}", isbn, isbn13, mvId);
            }

            if (mvId != null) {
                java.util.Map<String,Object> row = movieReviewDAO.selectMovieSummary(mvId);
                Map<String,Object> data = new HashMap<>();
                if (row != null) {
                    Object avg = row.get("AVG_RATING") != null ? row.get("AVG_RATING") : row.get("avg_rating");
                    Object rCnt = row.get("RATING_CNT") != null ? row.get("RATING_CNT") : row.get("rating_cnt");
                    Object readCnt = row.get("READ_CNT") != null ? row.get("READ_CNT") : row.get("read_cnt");
                    Object reviewWithTextCnt = row.get("REVIEW_WITH_TEXT_CNT") != null ? row.get("REVIEW_WITH_TEXT_CNT") : row.get("review_with_text_cnt");
                    Object likeCnt = null;
                    if (reviewWithTextCnt != null) {
                        likeCnt = reviewWithTextCnt;
                    } else {
                        likeCnt = row.get("LIKE_CNT") != null ? row.get("LIKE_CNT") : row.get("like_cnt");
                    }

                    data.put("avgRating", avg != null ? avg : null);
                    data.put("ratingCount", rCnt != null ? rCnt : 0);
                    data.put("readCount", readCnt != null ? readCnt : 0);
                    data.put("likeCount", likeCnt != null ? likeCnt : 0);
                    // expose reviewCount (reviews or one-line comments count)
                    data.put("reviewCount", reviewWithTextCnt != null ? reviewWithTextCnt : 0);
                } else {
                    data.put("avgRating", null);
                    data.put("ratingCount", 0);
                    data.put("readCount", 0);
                    data.put("likeCount", 0);
                    data.put("reviewCount", 0);
                }
                logger.info("[SUMMARY] returning data={}", data);
                result.put("status","OK"); result.put("data", data); return result;
            }

            java.util.Map<String,Object> row = reviewDAO.selectBookSummary(isbn, isbn13);
            Map<String,Object> data = new HashMap<>();
            if (row != null) {
                Object avg = row.get("AVG_RATING") != null ? row.get("AVG_RATING") : row.get("avg_rating");
                Object rCnt = row.get("RATING_CNT") != null ? row.get("RATING_CNT") : row.get("rating_cnt");
                Object readCnt = row.get("READ_CNT") != null ? row.get("READ_CNT") : row.get("read_cnt");
                // Prefer REVIEW_WITH_TEXT_CNT as the "likeCount" semantic requested: number of reviews that have CMNT or REVIEW_TEXT
                Object reviewWithTextCnt = row.get("REVIEW_WITH_TEXT_CNT") != null ? row.get("REVIEW_WITH_TEXT_CNT") : row.get("review_with_text_cnt");
                Object likeCnt = null;
                if (reviewWithTextCnt != null) {
                    likeCnt = reviewWithTextCnt;
                } else {
                    likeCnt = row.get("LIKE_CNT") != null ? row.get("LIKE_CNT") : row.get("like_cnt");
                }

                data.put("avgRating", avg != null ? avg : null);
                data.put("ratingCount", rCnt != null ? rCnt : 0);
                data.put("readCount", readCnt != null ? readCnt : 0);
                data.put("likeCount", likeCnt != null ? likeCnt : 0);
                data.put("reviewCount", reviewWithTextCnt != null ? reviewWithTextCnt : 0);
            } else {
                data.put("avgRating", null);
                data.put("ratingCount", 0);
                data.put("readCount", 0);
                data.put("likeCount", 0);
                data.put("reviewCount", 0);
            }
            logger.info("[SUMMARY] returning data={}", data);
            result.put("status","OK"); result.put("data", data); return result;
        } catch (Exception ex) {
            logger.error("[SUMMARY] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/reaction", produces = "application/json")
    @ResponseBody
    public Map<String,Object> userReaction(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        logger.info("[REACTION] endpoint invoked: uri={}, remoteAddr={}, query={}", request.getRequestURI(), request.getRemoteAddr(), request.getQueryString());
        try {
            com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null; String regDt = null; Integer mvId = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    if (payload.get("regDt") != null) regDt = String.valueOf(payload.get("regDt"));
                    if (payload.get("mvId") != null) try { mvId = Integer.valueOf(String.valueOf(payload.get("mvId"))); } catch(Exception ignore) {}
                    parsedJson = true;
                    logger.info("[REACTION] parsed JSON payload: isbn={}, isbn13={}, regDt={}, mvId={}", isbn, isbn13, regDt, mvId);
                }
            } catch (Exception ex) { logger.info("[REACTION] json parse failed: {}", ex.getMessage()); }
            if (!parsedJson) {
                if (request.getParameter("isbn") != null) isbn = request.getParameter("isbn");
                if (request.getParameter("isbn13") != null) isbn13 = request.getParameter("isbn13");
                if (request.getParameter("regDt") != null) regDt = request.getParameter("regDt");
                if (request.getParameter("mvId") != null) try { mvId = Integer.valueOf(request.getParameter("mvId")); } catch(Exception ignore) {}
                logger.info("[REACTION] parsed params: isbn={}, isbn13={}, regDt={}, mvId={}", isbn, isbn13, regDt, mvId);
            }

            if ((regDt == null || regDt.trim().length() == 0) ) { result.put("status","ERR"); result.put("message","MISSING_REGDT"); return result; }

            if (mvId != null) {
                Integer reaction = movieReviewDAO.selectUserReaction(userId, mvId, regDt);
                Map<String,Object> data = new HashMap<>();
                data.put("reaction", reaction);
                result.put("status","OK"); result.put("data", data);
                return result;
            }

            Integer reaction = reviewDAO.selectUserReaction(userId, isbn, isbn13, regDt);
            Map<String,Object> data = new HashMap<>();
            data.put("reaction", reaction);
            result.put("status","OK"); result.put("data", data);
            return result;
        } catch (Exception ex) {
            logger.error("[REACTION] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
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

    // New: return logged-in user's read items (for /review/my)
    @RequestMapping(value = "/my", method = {RequestMethod.GET, RequestMethod.POST}, produces = "application/json")
    @ResponseBody
    public Map<String,Object> myReadItems(HttpSession session, HttpServletRequest request, @RequestParam(value = "offset", required = false) Integer offset, @RequestParam(value = "limit", required = false) Integer limit) {
        Map<String,Object> result = new HashMap<>();
        try {
            logger.info("[MY] invoked via {} from {}", request.getMethod(), request.getRemoteAddr());
             com.mn.cm.model.User u = (com.mn.cm.model.User) session.getAttribute("USER_SESSION");
             if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
             String userId = String.valueOf(u.getId());
            if (offset == null) offset = 0;
            if (limit == null) limit = 200;
            java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectReadByUser(userId, offset, limit);
            // normalize datetime fields to string similar to other endpoints
            try {
                java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                for (java.util.Map<String,Object> r : rows) {
                    if (r == null) continue;
                    Object reg = r.get("REG_DT");
                    if (reg == null) reg = r.get("reg_dt");
                    if (reg != null) {
                        try {
                            if (reg instanceof java.time.LocalDateTime) {
                                r.put("REG_DT", ((java.time.LocalDateTime)reg).format(dtf));
                            } else if (reg instanceof java.sql.Timestamp) {
                                java.sql.Timestamp ts = (java.sql.Timestamp) reg;
                                r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(ts.getTime())));
                            } else if (reg instanceof java.util.Date) {
                                r.put("REG_DT", new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format((java.util.Date)reg));
                            } else if (reg instanceof String) {
                                r.put("REG_DT", String.valueOf(reg));
                            } else {
                                r.put("REG_DT", String.valueOf(reg));
                            }
                        } catch (Exception ex) {
                            try { r.put("REG_DT", String.valueOf(reg)); } catch(Exception ignore) {}
                        }
                    }
                }
            } catch (Exception ex) { /* ignore */ }

            result.put("status","OK"); result.put("data", rows); return result;
        } catch (Exception ex) {
            logger.error("[MY] error", ex);
            result.put("status","ERR"); result.put("message",ex.getMessage()); return result;
        }
    }

}
