package com.mn.cm.dao;

import java.util.List;
import java.util.Map;

public interface NoticeMapper {
    List<Map<String,Object>> selectNoticeList();
    Map<String,Object> selectNoticeById(long noticeId);
    void increaseViewCount(long noticeId);
}
