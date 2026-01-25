package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Repository
public class MovieReviewDAO {

    @Autowired
    private SqlSession sqlSession;

    private static final Logger logger = LoggerFactory.getLogger(MovieReviewDAO.class);

    public void insertOrUpdateReview(String userId, Integer mvId, Double rating, String cmnt, String reviewText) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("mvId", mvId != null ? mvId : null);
        params.put("readYn", "Y");
        params.put("rating", rating);
        params.put("cmnt", cmnt);
        params.put("reviewText", reviewText);
        sqlSession.getMapper(MovieReviewMapper.class).insertOrUpdateReview(params);
    }

    public void setReadStatus(String userId, Integer mvId, String readYn) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("mvId", mvId != null ? mvId : null);
        params.put("readYn", (readYn != null && (readYn.equals("Y") || readYn.equals("N"))) ? readYn : "Y");
        sqlSession.getMapper(MovieReviewMapper.class).insertOrUpdateRead(params);
    }

    public java.util.List<java.util.Map<String,Object>> selectStatuses(String userId, java.util.List<Integer> mvIds) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("mvIds", mvIds == null ? new java.util.ArrayList<Integer>() : mvIds);
        return sqlSession.getMapper(MovieReviewMapper.class).selectStatuses(params);
    }

    public void deleteReview(String userId, Integer mvId) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("mvId", mvId != null ? mvId : null);
        sqlSession.getMapper(MovieReviewMapper.class).deleteReview(params);
    }

    public java.util.List<java.util.Map<String,Object>> selectReviews(Integer mvId, Integer limit) {
        Map<String, Object> params = new HashMap<>();
        params.put("mvId", mvId != null ? mvId : null);
        params.put("limit", limit);
        return sqlSession.getMapper(MovieReviewMapper.class).selectReviews(params);
    }

    public java.util.Map<String,Object> selectMovieSummary(Integer mvId) {
        Map<String, Object> params = new HashMap<>();
        params.put("mvId", mvId != null ? mvId : null);
        return sqlSession.selectOne("com.mn.cm.dao.MovieReviewMapper.selectMovieSummary", params);
    }

    public java.util.List<java.util.Map<String,Object>> selectReadByUser(String userId, Integer offset, Integer limit) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("offset", (offset != null) ? offset : 0);
        params.put("limit", (limit != null) ? limit : null);
        return sqlSession.selectList("com.mn.cm.dao.MovieReviewMapper.selectReadByUser", params);
    }

    // New methods for reactions and lookup
    public void voteReview(String userId, Integer mvId, String regDt, String action) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("mvId", mvId);
        params.put("regDt", (regDt != null) ? regDt : "");
        params.put("action", (action != null) ? action : "");
        sqlSession.getMapper(MovieReviewMapper.class).voteReview(params);
    }

    public java.util.Map<String,Object> selectReviewByKey(Integer mvId, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("mvId", mvId);
        params.put("regDt", (regDt != null) ? regDt : "");
        return sqlSession.selectOne("com.mn.cm.dao.MovieReviewMapper.selectReviewByKey", params);
    }

    public Integer selectUserReaction(String userId, Integer mvId, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("mvId", mvId);
        params.put("regDt", (regDt != null) ? regDt : "");
        return sqlSession.selectOne("com.mn.cm.dao.MovieReviewMapper.selectUserReaction", params);
    }

    public void deleteUserReaction(String userId, Integer mvId, String regDt) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("mvId", mvId);
        params.put("regDt", (regDt != null) ? regDt : "");
        sqlSession.delete("com.mn.cm.dao.MovieReviewMapper.deleteUserReaction", params);
    }

    public java.util.List<java.util.Map<String,Object>> selectMovieSummaries(java.util.List<Integer> mvIds) {
        Map<String, Object> params = new HashMap<>();
        params.put("mvIds", mvIds == null ? new java.util.ArrayList<Integer>() : mvIds);
        return sqlSession.selectList("com.mn.cm.dao.MovieReviewMapper.selectMovieSummaries", params);
    }
}