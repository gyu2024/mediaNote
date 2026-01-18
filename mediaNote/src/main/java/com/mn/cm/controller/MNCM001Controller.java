package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.json.JSONArray;
import org.json.JSONObject;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.converter.StringHttpMessageConverter;
import java.nio.charset.StandardCharsets;
import com.mn.cm.model.AladinBook;
import com.mn.cm.dao.AladinBookDAO;

@Controller
public class MNCM001Controller {
	
	// 1. DAO를 필드 주입으로 선언합니다.
    @Autowired
    private AladinBookDAO aladinBookDAO;

	@RequestMapping(value="/hello", produces="application/json; charset=UTF-8")
    @ResponseBody
    public String search(HttpServletRequest request) {
        System.out.println("[알라딘API] 요청 시작");
        String mediaType = request.getParameter("mediaType");
        String query = request.getParameter("query");
        String target = request.getParameter("target");
        String region = request.getParameter("region");
        System.out.println("[알라딘API] 파라미터 수집: mediaType=" + mediaType + ", query=" + query + ", target=" + target + ", region=" + region);

        // 알라딘 API 파라미터 조립
        String ttbKey = "ttbomingyu2010001"; // 실제 알라딘 TTBKey로 교체
        String apiUrl = "https://www.aladin.co.kr/ttb/api/ItemSearch.aspx";
        StringBuilder urlBuilder = new StringBuilder(apiUrl);
        urlBuilder.append("?ttbkey=").append(ttbKey);
        urlBuilder.append("&Query=").append(query != null ? query : "");
        urlBuilder.append("&QueryType=").append(target != null && target.equals("author") ? "Author" : "Title");
        urlBuilder.append("&MaxResults=10");
        urlBuilder.append("&start=1");
        urlBuilder.append("&Cover=Small");
        urlBuilder.append("&SearchTarget=Book");
        urlBuilder.append("&output=js");
        urlBuilder.append("&Version=20131101");
		/*
		 * if (region != null) { if (region.equals("domestic"))
		 * urlBuilder.append("&Cover=Big&CategoryId=1"); else if
		 * (region.equals("foreign")) urlBuilder.append("&Cover=Big&CategoryId=55889");
		 * }
		 */
        String requestUrl = urlBuilder.toString();
        System.out.println("[알라딘API] 요청 URL: " + requestUrl);

        try {
            RestTemplate restTemplate = new RestTemplate();
            restTemplate.getMessageConverters().add(0, new StringHttpMessageConverter(StandardCharsets.UTF_8));
            System.out.println("[알라딘API] API 호출 시작");
            String result = restTemplate.getForObject(requestUrl, String.class);
            System.out.println("[알라딘API] API 응답 수신: " + (result != null ? result.substring(0, Math.min(result.length(), 200)) + "..." : "null"));
            JSONObject json = new JSONObject(result);
            System.out.println("[알라딘API] JSON 파싱 성공");
            JSONArray items = json.getJSONArray("item");
            System.out.println("[알라딘API] 아이템 개수: " + items.length());
            JSONArray books = new JSONArray();
            System.out.println("[알라딘API] 데이터 추출 시작 (총 " + items.length() + "건)");

            for (int i = 0; i < items.length(); i++) {
                JSONObject item = items.getJSONObject(i);
                JSONObject book = new JSONObject();
                
                // item의 모든 데이터를 한 줄의 String으로 출력
                System.out.println("Item " + i + " 전체 내용: " + item.toString());
                
                // 개별 필드 추출
                String title = item.optString("title");
                String author = item.optString("author");
                String publisher = item.optString("publisher");
                String cover = item.optString("cover");
                String pubDate = item.optString("pubDate");
                // DB 저장용 필드 추출
                String isbn13 = item.optString("isbn13");
                String isbn = item.optString("isbn");
                // Normalize isbn13
                if (isbn13 != null) {
                    isbn13 = isbn13.replaceAll("[^0-9Xx]", "");
                }
                // If isbn is missing, fall back to isbn13 (strip non-digits)
                if (isbn == null || isbn.trim().isEmpty()) {
                    if (isbn13 != null && !isbn13.trim().isEmpty()) {
                        isbn = isbn13;
                    }
                } else {
                    // normalize isbn by removing non-digit/X characters
                    isbn = isbn.replaceAll("[^0-9Xx]", "");
                }
                String link = item.optString("link");
                int priceStandard = item.optInt("priceStandard", 0);
                int priceSales = item.optInt("priceSales", 0);
                String categoryName = item.optString("categoryName");
                String categoryId = item.optString("categoryId");
                int customerReviewRank = item.optInt("customerReviewRank", 0);
                int salesPoint = item.optInt("salesPoint", 0);
                int itemId = item.optInt("itemId", 0);
                String mallType = item.optString("mallType");
                String description = item.optString("description");
                // 로그 출력: 현재 몇 번째 아이템을 처리 중인지와 제목/저자 확인
                System.out.println(String.format("[알라딘API] [%d/%d] 추출 데이터: 제목=%s, 저자=%s", (i + 1), items.length(), title, author));
                // 로그 출력: ISBN 정보 디버그
                System.out.println(String.format("[알라딘API] [%d/%d] ISBN13=%s, ISBN=%s", (i + 1), items.length(), isbn13, isbn));

                book.put("title"	, title);
                book.put("author"	, author);
                book.put("publisher", publisher);
                book.put("cover"	, cover);
                book.put("pubDate"	, pubDate);
                book.put("isbn"		, isbn);
                book.put("isbn13"	, isbn13);
                
                books.put(book);
                // DB 저장
                AladinBook bookEntity = new AladinBook();
                bookEntity.setIsbn13(isbn13);
                bookEntity.setIsbn(isbn);
                bookEntity.setTitle(title);
                bookEntity.setAuthor(author);
                bookEntity.setPublisher(publisher);
                bookEntity.setPubDate(pubDate);
                bookEntity.setDescription(description);
                bookEntity.setCover(cover);
                bookEntity.setLink(link);
                bookEntity.setPriceStandard(priceStandard);
                bookEntity.setPriceSales(priceSales);
                bookEntity.setCategoryName(categoryName);
                bookEntity.setCategoryId(categoryId);
                bookEntity.setCustomerReviewRank(customerReviewRank);
                bookEntity.setSalesPoint(salesPoint);
                bookEntity.setItemId(itemId);
                bookEntity.setMallType(mallType);

                try {
                    aladinBookDAO.insert(bookEntity);
                } catch (com.mn.cm.dao.DuplicateIsbnException dupEx) {
                    // Duplicate ISBN: skip inserting and log info
                    System.out.println("[알라딘API] 중복 ISBN으로 스킵: " + dupEx.getMessage());
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }
            System.out.println("[알라딘API] 결과 반환: " + books.length() + "권");
            return books.toString();
        } catch (Exception e) {
            System.out.println("[알라딘API] 예외 발생: " + e.getMessage());
            e.printStackTrace();
            return "[]";
        }
    }
}