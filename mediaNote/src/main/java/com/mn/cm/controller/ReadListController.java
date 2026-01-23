package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.view.RedirectView;
import com.mn.cm.model.User;
import org.springframework.beans.factory.annotation.Autowired;
import com.mn.cm.dao.ReviewDAO;

@Controller
public class ReadListController {

    @Autowired
    private ReviewDAO reviewDAO;

    @GetMapping("/readList")
    public Object readList(HttpServletRequest request, HttpServletResponse response) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/readList.jsp");
        }

        User u = (User) session.getAttribute("USER_SESSION");
        if (u == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/readList.jsp");
        }

        try {
            // Fetch the user's read items (no pagination for now)
            java.util.List<java.util.Map<String,Object>> items = reviewDAO.selectReadByUser(String.valueOf(u.getId()), 0, 200);
            request.setAttribute("readItems", items);
            request.getRequestDispatcher("/readList.jsp").forward(request, response);
            return null;
        } catch (Exception ex) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/readList.jsp");
        }
    }
}