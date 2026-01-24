 package com.mn.cm.dao;

import java.util.List;
import java.util.Map;

public interface MovieReviewMapper {
    void insertOrUpdateReview(Map<String, Object> params);
    void insertOrUpdateRead(Map<String, Object> params);
    List<Map<String, Object>> selectStatuses(Map<String, Object> params);
    List<Map<String, Object>> selectReviews(Map<String, Object> params);
    Map<String, Object> selectMovieSummary(Map<String, Object> params);
    void deleteReview(Map<String, Object> params);
    void voteReview(Map<String, Object> params);
    Map<String, Object> selectReviewByKey(Map<String, Object> params);
    Integer selectUserReaction(Map<String, Object> params);
    void deleteUserReaction(Map<String, Object> params);
    List<Map<String, Object>> selectReadByUser(Map<String, Object> params);
}
