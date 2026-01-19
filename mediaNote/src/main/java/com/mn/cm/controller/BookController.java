package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.ui.Model;
import org.springframework.beans.factory.annotation.Autowired;
import com.mn.cm.dao.AladinBookDAO;
import com.mn.cm.model.AladinBook;

@Controller
public class BookController {

    @Autowired
    private AladinBookDAO aladinBookDAO;

    @GetMapping("/book/view")
    public String viewBook(@RequestParam(name = "isbn", required = false) String isbn,
                           Model model) {
        if (isbn == null || isbn.trim().length() == 0) {
            return "redirect:/index.jsp";
        }
        AladinBook b = aladinBookDAO.selectByIsbn(isbn);
        if (b == null) {
            model.addAttribute("message", "도서를 찾을 수 없습니다.");
            return "bookDetail"; // show page with message
        }
        model.addAttribute("book", b);
        return "bookDetail";
    }
}
