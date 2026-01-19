package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import java.util.Map;
import java.util.HashMap;
import com.mn.cm.dao.WishDAO;
import com.mn.cm.model.User;

@Controller
@RequestMapping("/wish")
public class WishController {

    @Autowired
    private WishDAO wishDAO;

    private static final Logger logger = LoggerFactory.getLogger(WishController.class);
    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping(value = "/add", produces = "application/json")
    @ResponseBody
    public Map<String,Object> addWish(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            User u = (User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            // For MN_BK_WISH.ISBN not nullable, prefer isbn and fallback to isbn13
            String isbnForTable = (isbn != null && isbn.trim().length()>0) ? isbn.trim() : (isbn13 != null ? isbn13.trim() : "");
            String isbn13ForTable = (isbn13 != null && isbn13.trim().length()>0) ? isbn13.trim() : null;

            wishDAO.insertOrUpdateWish(userId, isbnForTable, isbn13ForTable);
            result.put("status","OK");
            return result;
        } catch (Exception ex) {
            logger.error("[WISH ADD] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/remove", produces = "application/json")
    @ResponseBody
    public Map<String,Object> removeWish(HttpServletRequest request, HttpSession session) {
        Map<String,Object> result = new HashMap<>();
        try {
            User u = (User) session.getAttribute("USER_SESSION");
            if (u == null) { result.put("status","ERR"); result.put("message","NOT_LOGGED_IN"); return result; }
            String userId = String.valueOf(u.getId());

            String isbn = null; String isbn13 = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
            }

            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }

            // prefer isbn when removing, fallback to isbn13
            String isbnForTable = (isbn != null && isbn.trim().length()>0) ? isbn.trim() : (isbn13 != null ? isbn13.trim() : "");
            String isbn13ForTable = (isbn13 != null && isbn13.trim().length()>0) ? isbn13.trim() : null;

            wishDAO.deleteWish(userId, isbnForTable, isbn13ForTable);
            result.put("status","OK");
            return result;
        } catch (Exception ex) {
            logger.error("[WISH REMOVE] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }

    @PostMapping(value = "/count", produces = "application/json")
    @ResponseBody
    public Map<String,Object> countWish(HttpServletRequest request) {
        Map<String,Object> result = new HashMap<>();
        try {
            String isbn = null; String isbn13 = null;
            String contentType = request.getContentType();
            boolean parsedJson = false;
            try {
                if (contentType != null && contentType.toLowerCase().contains("application/json")) {
                    Map<String,Object> payload = objectMapper.readValue(request.getInputStream(), Map.class);
                    if (payload.get("isbn") != null) isbn = String.valueOf(payload.get("isbn"));
                    if (payload.get("isbn13") != null) isbn13 = String.valueOf(payload.get("isbn13"));
                    parsedJson = true;
                }
            } catch (Exception ex) { }
            if (!parsedJson) {
                String pIsbn = request.getParameter("isbn");
                String pIsbn13 = request.getParameter("isbn13");
                if (pIsbn != null && pIsbn.trim().length()>0) isbn = pIsbn.trim();
                if (pIsbn13 != null && pIsbn13.trim().length()>0) isbn13 = pIsbn13.trim();
            }
            if ((isbn == null || isbn.trim().length() == 0) && (isbn13 == null || isbn13.trim().length() == 0)) {
                result.put("status","ERR"); result.put("message","MISSING_ISBN"); return result;
            }
            long cnt = wishDAO.selectWishCount(isbn, isbn13);
            result.put("status","OK"); result.put("data", java.util.Collections.singletonMap("count", cnt));

            // Also include whether current user has wished this book (if logged in)
            com.mn.cm.model.User u = (com.mn.cm.model.User) request.getSession().getAttribute("USER_SESSION");
            if (u != null) {
                long has = wishDAO.selectUserWishCount(String.valueOf(u.getId()), isbn, isbn13);
                result.put("userHasWish", has > 0);
                // also attach userWishCount for compatibility
                result.put("userWishCount", has);
            }

            return result;
        } catch (Exception ex) {
            logger.error("[WISH COUNT] error", ex);
            result.put("status","ERR"); result.put("message", ex.getMessage()); return result;
        }
    }
}