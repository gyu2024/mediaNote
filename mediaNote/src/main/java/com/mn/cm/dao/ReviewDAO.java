package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import java.util.HashMap;
import java.util.Map;

@Repository
public class ReviewDAO {

    @Autowired
    private SqlSession sqlSession;

    // Accept separate isbn and isbn13 so we don't write fallback ids into both columns
    public void insertOrUpdateReview(String userId, String isbn, String isbn13, Double rating, String comnet, String reviewText) {
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        // Prefer putting real isbn13 into ISBN13 column, otherwise null
        params.put("isbn13", (isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null);
        // Put isbn into ISBN column; if missing but isbn13 exists, use isbn13 as fallback for isbn
        params.put("isbn", (isbn != null && !isbn.trim().isEmpty()) ? isbn : ((isbn13 != null && !isbn13.trim().isEmpty()) ? isbn13 : null));
        params.put("readYn", "Y");
        params.put("rating", rating);
        params.put("comnet", comnet);
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
}