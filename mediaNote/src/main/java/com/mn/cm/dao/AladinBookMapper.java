package com.mn.cm.dao;

import com.mn.cm.model.AladinBook;

public interface AladinBookMapper {
    void insertAladinBook(AladinBook book);
    AladinBook selectByIsbn(String isbn);
}