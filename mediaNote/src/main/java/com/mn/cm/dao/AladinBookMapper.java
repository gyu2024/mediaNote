package com.mn.cm.dao;

import com.mn.cm.model.AladinBook;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AladinBookMapper {
    void insertAladinBook(AladinBook book);
    AladinBook selectByIsbn(String isbn);
    List<AladinBook> selectList(@Param("offset") int offset, @Param("limit") int limit);
}