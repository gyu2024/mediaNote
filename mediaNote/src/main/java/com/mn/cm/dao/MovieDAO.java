package com.mn.cm.dao;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;
import org.mybatis.spring.SqlSessionTemplate;
import com.mn.cm.model.Movie;

import java.util.HashMap;
import java.util.Map;

@Repository
public class MovieDAO {

    @Autowired
    private SqlSessionTemplate sqlSessionTemplate;

    public int insertMovie(Movie m) {
        return sqlSessionTemplate.insert("com.mn.cm.dao.MovieMapper.insertMovie", m);
    }

    public Movie selectByMvId(int mvId) {
        return sqlSessionTemplate.selectOne("com.mn.cm.dao.MovieMapper.selectByMvId", mvId);
    }

    public Movie selectByTitleAndRelease(String title, java.sql.Date releaseDate) {
        Map<String, Object> params = new HashMap<>();
        params.put("title", title);
        params.put("releaseDate", releaseDate);
        return sqlSessionTemplate.selectOne("com.mn.cm.dao.MovieMapper.selectByTitleAndRelease", params);
    }

    public Movie selectByTitle(String title) {
        return sqlSessionTemplate.selectOne("com.mn.cm.dao.MovieMapper.selectByTitle", title);
    }
}