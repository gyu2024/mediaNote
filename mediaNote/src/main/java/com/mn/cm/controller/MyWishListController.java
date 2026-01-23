package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.view.RedirectView;
import com.mn.cm.model.User;
import org.springframework.beans.factory.annotation.Autowired;
import com.mn.cm.dao.WishDAO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Controller
public class MyWishListController {

    private static final Logger logger = LoggerFactory.getLogger(MyWishListController.class);

    @Autowired
    private WishDAO wishDAO;

    @GetMapping("/MyPage/MyWishList")
    public Object myWishList(HttpServletRequest request, HttpServletResponse response) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/MyPage/MyWishList");
        }

        User u = (User) session.getAttribute("USER_SESSION");
        if (u == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/MyPage/MyWishList");
        }

        try {
            // fetch user's wishes for possible server-side rendering (optional)
            java.util.List<java.util.Map<String,Object>> items = wishDAO.selectWishesByUser(String.valueOf(u.getId()), 0, 200);
            request.setAttribute("wishItems", items);
            request.getRequestDispatcher("/wishList.jsp").forward(request, response);
            return null;
        } catch (Exception ex) {
            // Log full stacktrace so underlying SQLException (error code 1267) is visible in server logs
            logger.error("[MYWISH] error while fetching wishlist for user {}", (u != null ? u.getId() : "<unknown>"), ex);
            try {
                request.setAttribute("wishItems", java.util.Collections.emptyList());
                request.setAttribute("wishError", ex.getMessage());
                request.getRequestDispatcher("/wishList.jsp").forward(request, response);
                return null;
            } catch (Exception forwardEx) {
                logger.error("[MYWISH] failed to forward to wishList.jsp", forwardEx);
                String ctx = request.getContextPath();
                return new RedirectView(ctx + "/wishList.jsp");
            }
        }
    }
}