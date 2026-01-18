package com.mn.cm.dao;

import com.mn.cm.model.UserMaster;

public interface UserMasterMapper {
    // Select by userId
    UserMaster selectByUserId(String userId);

    // Insert new user
    void insertUserMaster(UserMaster user);

    // Update last login for existing user
    void updateLastLogin(UserMaster user);

    // Combined upsert - MyBatis can map to custom SQL
    void insertOrUpdateLogin(UserMaster user);
}