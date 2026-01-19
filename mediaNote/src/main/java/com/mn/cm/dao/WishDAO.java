package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import java.util.HashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Repository
public class WishDAO {

    @Autowired
    private SqlSession sqlSession;

    private static final Logger logger = LoggerFactory.getLogger(WishDAO.class);

    public void insertOrUpdateWish(String userId, String isbn, String isbn13) {
        Map<String,Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("isbn13", (isbn13 != null && isbn13.trim().length()>0) ? isbn13 : null);
        // MN_BK_WISH.ISBN is NOT NULL in schema; if isbn missing, use isbn13 as fallback
        params.put("isbn", (isbn != null && isbn.trim().length()>0) ? isbn : ((isbn13 != null) ? isbn13 : null));
        sqlSession.insert("com.mn.cm.dao.WishMapper.insertOrUpdateWish", params);
    }

    public void deleteWish(String userId, String isbn, String isbn13) {
        Map<String,Object> params = new HashMap<>();
        params.put("userId", userId);
        params.put("isbn", (isbn != null && isbn.trim().length()>0) ? isbn : null);
        params.put("isbn13", (isbn13 != null && isbn13.trim().length()>0) ? isbn13 : null);
        sqlSession.delete("com.mn.cm.dao.WishMapper.deleteWish", params);
    }

    public long selectWishCount(String isbn, String isbn13) {
        Map<String,Object> params = new HashMap<>();
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        Long cnt = sqlSession.selectOne("com.mn.cm.dao.WishMapper.selectWishCount", params);
        return (cnt == null) ? 0L : cnt.longValue();
    }

    // returns number of rows for this user+isbn (0 or 1); used to determine if user has wished the book
    public long selectUserWishCount(String userId, String isbn, String isbn13) {
        Map<String,Object> params = new HashMap<>();
        params.put("userId", (userId != null) ? userId : "");
        params.put("isbn", (isbn != null) ? isbn : "");
        params.put("isbn13", (isbn13 != null) ? isbn13 : "");
        Long cnt = sqlSession.selectOne("com.mn.cm.dao.WishMapper.selectUserWishCount", params);
        return (cnt == null) ? 0L : cnt.longValue();
    }
}