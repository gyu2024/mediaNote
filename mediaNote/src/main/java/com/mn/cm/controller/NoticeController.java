package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.ui.Model;
import org.springframework.beans.factory.annotation.Autowired;
import com.mn.cm.dao.NoticeDAO;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.Map;
import java.util.HashMap;
import java.util.List;

@Controller
public class NoticeController {

    @Autowired
    private NoticeDAO noticeDAO;

    @GetMapping("/notice/list")
    public String list(Model model) {
        model.addAttribute("notices", noticeDAO.selectNoticeList());
        return "noticeList";
    }

    @GetMapping("/notice/view")
    public String view(@RequestParam(name = "id") long id, Model model) {
        // increase view count
        noticeDAO.increaseViewCount(id);
        model.addAttribute("notice", noticeDAO.selectNoticeById(id));
        return "noticeDetail";
    }

    @GetMapping("/notice/api/list")
    @ResponseBody
    public Map<String,Object> apiList() {
        Map<String,Object> result = new HashMap<>();
        try {
            List<Map<String,Object>> list = noticeDAO.selectNoticeList();
            result.put("status","OK");
            result.put("data", list);
        } catch (Exception ex) {
            result.put("status","ERR");
            result.put("message", ex.getMessage());
        }
        return result;
    }
}