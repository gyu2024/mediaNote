package com.mn.cm.dao;

import org.springframework.stereotype.Repository;
import org.springframework.beans.factory.annotation.Autowired;
import org.apache.ibatis.session.SqlSession;
import com.mn.cm.model.UserMaster;

@Repository
public class UserMasterDAO {

    @Autowired
    private SqlSession sqlSession;

    public UserMaster selectByUserId(String userId) {
        return sqlSession.getMapper(UserMasterMapper.class).selectByUserId(userId);
    }

    public void insertUserMaster(UserMaster user) {
        sqlSession.getMapper(UserMasterMapper.class).insertUserMaster(user);
    }

    public void updateLastLogin(UserMaster user) {
        sqlSession.getMapper(UserMasterMapper.class).updateLastLogin(user);
    }

    public void insertOrUpdateLogin(UserMaster user) {
        sqlSession.getMapper(UserMasterMapper.class).insertOrUpdateLogin(user);
    }
}