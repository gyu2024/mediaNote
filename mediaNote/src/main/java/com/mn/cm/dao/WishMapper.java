package com.mn.cm.dao;

public interface WishMapper {
    void insertOrUpdateWish(java.util.Map<String, Object> params);
    void deleteWish(java.util.Map<String, Object> params);
    Long selectWishCount(java.util.Map<String, Object> params);
}