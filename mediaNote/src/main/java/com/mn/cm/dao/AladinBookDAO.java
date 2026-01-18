package com.mn.cm.dao;

import com.mn.cm.model.AladinBook;
import org.apache.ibatis.session.SqlSession;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

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
}