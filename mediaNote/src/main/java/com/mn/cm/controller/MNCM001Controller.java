package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import jakarta.servlet.http.HttpServletRequest;

@Controller
public class MNCM001Controller {

    @RequestMapping(value="/hello") // .do 추가
    @ResponseBody
    public String search(HttpServletRequest request) {
        
        String mediaType = request.getParameter("mediaType");
        String query = request.getParameter("query");
        
        System.out.println("======= Spring MVC 검색 요청 수신 =======");
        System.out.println("미디어 타입: " + mediaType);
        System.out.println("검색어: " + query);

        if ("book".equals(mediaType)) {
            String target = request.getParameter("target");
            String region = request.getParameter("region");
            System.out.println("검색 기준: " + target);
            System.out.println("도서 구분: " + region);
        }
        System.out.println("=======================================");

        // AJAX의 success 함수로 전달될 메시지
        return "SUCCESS: " + query + " (Type: " + mediaType + ")"; 
    }
}