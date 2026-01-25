package com.mn.cm.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.mybatis.spring.SqlSessionTemplate;
import com.mn.cm.model.Genre;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Repository
public class GenreDAO {

    @Autowired
    private SqlSessionTemplate sqlSessionTemplate;

    public int upsertGenre(Genre g) {
        return sqlSessionTemplate.update("com.mn.cm.dao.GenreMapper.upsertGenre", g);
    }

    public int deleteAllForMedia(String mediaType) {
        return sqlSessionTemplate.delete("com.mn.cm.dao.GenreMapper.deleteAllForMedia", mediaType);
    }

    // New: select genre id->name mapping for a list of ids
    public java.util.List<java.util.Map<String,Object>> selectNamesByIds(List<Integer> ids) {
        Map<String,Object> params = new HashMap<>();
        params.put("ids", ids == null ? new java.util.ArrayList<Integer>() : ids);
        return sqlSessionTemplate.selectList("com.mn.cm.dao.GenreMapper.selectNamesByIds", params);
    }
}