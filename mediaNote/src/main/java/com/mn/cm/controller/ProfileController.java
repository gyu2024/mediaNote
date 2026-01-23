package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.view.RedirectView;
import org.springframework.beans.factory.annotation.Autowired;
import com.mn.cm.dao.UserMasterDAO;
import com.mn.cm.model.UserMaster;
import com.mn.cm.model.User;

@Controller
public class ProfileController {

    @Autowired
    private UserMasterDAO userMasterDAO;

    @GetMapping("/profile")
    public Object profile(HttpServletRequest request, HttpServletResponse response) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/profile.jsp");
        }

        User u = (User) session.getAttribute("USER_SESSION");
        if (u == null) {
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/login/kakao?returnUrl=/profile.jsp");
        }

        // Try to load UserMaster by userId (stored as string). Fall back to id -> string
        String userIdStr = (u.getId() != null) ? String.valueOf(u.getId()) : null;
        UserMaster um = null;
        try {
            if (userIdStr != null) {
                um = userMasterDAO.selectByUserId(userIdStr);
            }
        } catch (Exception e) {
            // ignore DB lookup errors here; we'll still render the page with session user info
        }

        if (um != null) request.setAttribute("userMaster", um);
        request.setAttribute("sessionUser", u);

        // Forward to JSP (use server-side forward so attributes are available)
        try {
            request.getRequestDispatcher("/profile.jsp").forward(request, response);
            return null;
        } catch (Exception ex) {
            // fallback redirect to profile.jsp
            String ctx = request.getContextPath();
            return new RedirectView(ctx + "/profile.jsp");
        }
    }
}