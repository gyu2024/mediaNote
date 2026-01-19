package com.mn.cm.dao;

import com.mn.cm.model.AladinBook;
import org.apache.ibatis.session.SqlSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class AladinBookDAO {
    @Autowired
    private SqlSession sqlSession;

    public void insert(AladinBook book) {
        if (book == null) return;
        String isbn = book.getIsbn();
        if (isbn != null && !isbn.trim().isEmpty()) {
            AladinBook existing = sqlSession.getMapper(AladinBookMapper.class).selectByIsbn(isbn);
            if (existing != null) {
                throw new DuplicateIsbnException("ISBN already exists: " + isbn);
            }
        }
        sqlSession.getMapper(AladinBookMapper.class).insertAladinBook(book);
    }

    // New: lookup an AladinBook by ISBN
    public AladinBook selectByIsbn(String isbn) {
        if (isbn == null) return null;
        try {
            return sqlSession.getMapper(AladinBookMapper.class).selectByIsbn(isbn);
        } catch (Exception ex) {
            return null;
        }
    }

    // New: paginated select fallback
    public List<AladinBook> selectList(int offset, int limit) {
        try {
            Map<String, Object> params = new HashMap<>();
            params.put("offset", offset);
            params.put("limit", limit);
            return sqlSession.getMapper(AladinBookMapper.class).selectList(offset, limit);
        } catch (Exception ex) {
            return null;
        }
    }
}