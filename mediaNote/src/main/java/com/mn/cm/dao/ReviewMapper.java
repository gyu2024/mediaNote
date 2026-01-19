package com.mn.cm.dao;

import java.util.Map;
import java.util.List;

public interface ReviewMapper {
    void insertOrUpdateReview(Map<String, Object> params);
    void insertOrUpdateRead(Map<String, Object> params);
    List<Map<String, Object>> selectStatuses(Map<String, Object> params);
    List<Map<String, Object>> selectReviews(Map<String, Object> params);
    void deleteReview(Map<String, Object> params);
    void voteReview(Map<String, Object> params);
    Map<String, Object> selectReviewByKey(Map<String, Object> params);
    Integer selectUserReaction(Map<String, Object> params);
}