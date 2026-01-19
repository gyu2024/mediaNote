package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@Repository
public class NoticeDAO {

    @Autowired
    private SqlSession sqlSession;

    public List<Map<String,Object>> selectNoticeList() {
        return sqlSession.selectList("com.mn.cm.dao.NoticeMapper.selectNoticeList");
    }

    public Map<String,Object> selectNoticeById(long noticeId) {
        return sqlSession.selectOne("com.mn.cm.dao.NoticeMapper.selectNoticeById", noticeId);
    }

    public void increaseViewCount(long noticeId) {
        sqlSession.update("com.mn.cm.dao.NoticeMapper.increaseViewCount", noticeId);
    }
}
