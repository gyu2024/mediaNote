package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Repository
public class ReviewDAO {

    @Autowired
    private SqlSession sqlSession;

    private static final Logger logger = LoggerFactory.getLogger(ReviewDAO.class);

    // Accept separate isbn and isbn13 so we don't write fallback ids into both columns
    public void insertOrUpdateReview(String userId, String isbn, String isbn13, Double rating, String cmnt, String reviewText) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        // Prefer putting real isbn13 into ISBN13 column, otherwise null
        params.put("isbn13", (isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null);
        // Put isbn into ISBN column; if missing but isbn13 exists, use isbn13 as fallback for isbn
        params.put("isbn", (isbn != null && !isbn.trim().isEmpty()) ? isbn : ((isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null));
        params.put("readYn", "Y");
        params.put("rating", rating);
        params.put("cmnt", cmnt);
        params.put("reviewText", reviewText);

        sqlSession.getMapper(ReviewMapper.class).insertOrUpdateReview(params);
    }

    public void setReadStatus(String userId, String isbn, String isbn13, String readYn) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("isbn13", (isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null);
        params.put("isbn", (isbn != null && !isbn.trim().isEmpty()) ? isbn : ((isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null));
        params.put("readYn", (readYn != null && (readYn.equals("Y") || readYn.equals("N"))) ? readYn : "Y");
        sqlSession.getMapper(ReviewMapper.class).insertOrUpdateRead(params);
    }

    public java.util.List<java.util.Map<String,Object>> selectStatuses(String userId, java.util.List<String> isbns, java.util.List<String> isbns13) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("isbns", isbns == null ? new java.util.ArrayList<String>() : isbns);
        params.put("isbns13", isbns13 == null ? new java.util.ArrayList<String>() : isbns13);
        return sqlSession.getMapper(ReviewMapper.class).selectStatuses(params);
    }

    public void deleteReview(String userId, String isbn, String isbn13) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("isbn", (isbn != null && isbn.trim().length() > 0) ? isbn : null);
        params.put("isbn13", (isbn13 != null && isbn13.trim().length() > 0) ? isbn13 : null);
        sqlSession.getMapper(ReviewMapper.class).deleteReview(params);
    }

    // New: fetch public reviews for display on detail page
    public java.util.List<java.util.Map<String,Object>> selectReviews(String isbn, String isbn13, Integer limit) {
        Map<String, Object> params = new HashMap<>();
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        params.put("limit", limit);
        return sqlSession.getMapper(ReviewMapper.class).selectReviews(params);
    }

    // Updated voteReview: record per-user reaction in MN_BK_LIKE and then refresh aggregated counts stored on MN_BK_RVW
    public void voteReview(String userId, String isbn, String isbn13, String regDt, String action) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        params.put("regDt", (regDt != null) ? regDt : "");
        params.put("action", (action != null) ? action : "");
        sqlSession.getMapper(ReviewMapper.class).voteReview(params);
    }

    // fetch a single review row (by isbn/isbn13 + regDt) to read current counts
    public java.util.Map<String,Object> selectReviewByKey(String isbn, String isbn13, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        params.put("regDt", (regDt != null) ? regDt : "");
        return sqlSession.selectOne("com.mn.cm.dao.ReviewMapper.selectReviewByKey", params);
    }

    // New: fetch book-level summary metrics
    public java.util.Map<String,Object> selectBookSummary(String isbn, String isbn13) {
        logger.info("[DAO] selectBookSummary called with isbn={} isbn13={}", isbn, isbn13);
        Map<String, Object> params = new HashMap<>();
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        java.util.Map<String,Object> r = sqlSession.selectOne("com.mn.cm.dao.ReviewMapper.selectBookSummary", params);
        logger.info("[DAO] selectBookSummary result={}", r);
        return r;
    }

    // New: check whether a specific user has reacted to a given review (returns LIKE_TYPE: 0=like,1=dislike or null if none)
    public Integer selectUserReaction(String userId, String isbn, String isbn13, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        params.put("regDt", (regDt != null) ? regDt : "");
        return sqlSession.selectOne("com.mn.cm.dao.ReviewMapper.selectUserReaction", params);
    }

    // New: delete user's reaction for a review (used to toggle off like/dislike)
    public void deleteUserReaction(String userId, String isbn, String isbn13, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        params.put("regDt", (regDt != null) ? regDt : "");
        sqlSession.delete("com.mn.cm.dao.ReviewMapper.deleteUserReaction", params);
    }
}