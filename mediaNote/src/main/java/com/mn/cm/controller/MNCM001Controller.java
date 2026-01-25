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
import com.mn.cm.dao.ReviewDAO;
import com.mn.cm.model.User;

@Controller
public class MNCM001Controller {
	
	// 1. DAO를 필드 주입으로 선언합니다.
    @Autowired
    private AladinBookDAO aladinBookDAO;
    // 로그인 사용자 리뷰/읽음 상태 조회를 위한 DAO
    @Autowired
    private ReviewDAO reviewDAO;

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
        urlBuilder.append("&Cover=Big");
        urlBuilder.append("&SearchTarget=Book");
        urlBuilder.append("&Sort=SalesPoint");
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

            // 로그인 사용자 확인 및 배치 상태 조회를 위한 ISBN 수집
            User user = null;
            try { user = (User) request.getSession().getAttribute("USER_SESSION"); } catch (Exception ignore) {}
            java.util.List<String> batchIsbns = new java.util.ArrayList<>();
            java.util.List<String> batchIsbns13 = new java.util.ArrayList<>();

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
                // ISBN 수집 (로그인된 경우 나중에 상태 조회)
                try {
                    if (isbn != null && isbn.trim().length() > 0) batchIsbns.add(isbn.trim());
                    if (isbn13 != null && isbn13.trim().length() > 0) batchIsbns13.add(isbn13.trim());
                } catch (Exception ignore) {}
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
            // 로그인 사용자라면, 수집된 ISBN들로 리뷰/읽음 상태를 DB에서 배치 조회하여 books에 플래그 추가
            try {
                if (user != null && (batchIsbns.size() > 0 || batchIsbns13.size() > 0)) {
                    // 중복 제거
                    batchIsbns = new java.util.ArrayList<>(new java.util.LinkedHashSet<>(batchIsbns));
                    batchIsbns13 = new java.util.ArrayList<>(new java.util.LinkedHashSet<>(batchIsbns13));
                    java.util.List<java.util.Map<String,Object>> rows = reviewDAO.selectStatuses(String.valueOf(user.getId()), batchIsbns, batchIsbns13);
                    // ISBN/ISBN13 기준으로 상태 맵 구성
                    java.util.Map<String, java.util.Map<String,Object>> statusByKey = new java.util.HashMap<>();
                    for (java.util.Map<String,Object> r : rows) {
                        if (r == null) continue;
                        String kIsbn = r.get("ISBN") != null ? String.valueOf(r.get("ISBN")) : null;
                        String kIsbn13 = r.get("ISBN13") != null ? String.valueOf(r.get("ISBN13")) : null;
                        java.util.Map<String,Object> st = new java.util.HashMap<>();
                        st.put("READ_YN", r.get("READ_YN"));
                        st.put("RATING", r.get("RATING"));
                        st.put("CMNT", r.get("CMNT"));
                        st.put("REVIEW_TEXT", r.get("REVIEW_TEXT"));
                        if (kIsbn != null && !kIsbn.trim().isEmpty()) statusByKey.put(kIsbn, st);
                        if (kIsbn13 != null && !kIsbn13.trim().isEmpty()) statusByKey.put(kIsbn13, st);
                    }
                    // books 배열을 돌면서 각 아이템에 userHasReview/userRead 플래그 주입
                    for (int i = 0; i < books.length(); i++) {
                        try {
                            JSONObject b = books.getJSONObject(i);
                            String bi = b.optString("isbn");
                            String bi13 = b.optString("isbn13");
                            java.util.Map<String,Object> st = null;
                            if (bi != null && statusByKey.containsKey(bi)) st = statusByKey.get(bi);
                            else if (bi13 != null && statusByKey.containsKey(bi13)) st = statusByKey.get(bi13);
                            boolean hasReview = false;
                            boolean hasRead = false;
                            if (st != null) {
                                Object ratingObj = st.get("RATING");
                                Object cmntObj = st.get("CMNT");
                                Object reviewTextObj = st.get("REVIEW_TEXT");
                                if (ratingObj != null) hasReview = true;
                                if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                                Object ryn = st.get("READ_YN");
                                if (ryn != null) {
                                    String s = String.valueOf(ryn).trim();
                                    if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) hasRead = true;
                                }
                            }
                            b.put("userHasReview", hasReview);
                            b.put("userRead", hasRead);
                        } catch (Exception ignore) {}
                    }
                }
            } catch (Exception ex) {
                System.out.println("[알라딘API] 사용자 리뷰/읽음 상태 주입 실패: " + ex.getMessage());
            }
            System.out.println("[알라딘API] 결과 반환: " + books.length() + "권");
            return books.toString();
        } catch (Exception e) {
            System.out.println("[알라딘API] 예외 발생: " + e.getMessage());
            e.printStackTrace();
            return "[]";
        }
    }

    // New endpoint: bestseller list
    @RequestMapping(value="/bestseller", produces="application/json; charset=UTF-8")
    @ResponseBody
    public String bestseller(HttpServletRequest request) {
        System.out.println("[알라딘API][베스트셀러] 요청 시작");
        String searchTarget = request.getParameter("SearchTarget"); // optional: Book, Foreign, Music, DVD, Used, eBook, All
        String start = request.getParameter("Start");
        String maxResults = request.getParameter("MaxResults");
        String categoryId = request.getParameter("CategoryId");
        String year = request.getParameter("Year");
        String month = request.getParameter("Month");
        String week = request.getParameter("Week");

        String ttbKey = "ttbomingyu2010001"; // 실제 키로 교체
        // parse start/max early to allow DB fallback when Start is large
        int startInt = (int)(Math.random() * 90) + 1;
        int maxInt = 20;

        // If start beyond API limit (historically ~490), return DB fallback directly to avoid useless API call
        if (startInt > 490) {
            try {
                int offset = Math.max(0, startInt - 1);
                java.util.List<AladinBook> list = aladinBookDAO.selectList(offset, maxInt);
                JSONArray books = new JSONArray();
                if (list != null && !list.isEmpty()) {
                    for (AladinBook ab : list) {
                        JSONObject b = new JSONObject();
                        b.put("title", ab.getTitle());
                        b.put("author", ab.getAuthor());
                        b.put("publisher", ab.getPublisher());
                        b.put("cover", ab.getCover());
                        b.put("pubDate", ab.getPubDate());
                        b.put("isbn", ab.getIsbn());
                        b.put("isbn13", ab.getIsbn13());
                        books.put(b);
                    }
                }
                return books.toString();
            } catch (Exception ex) {
                ex.printStackTrace();
                return "[]";
            }
        }

        String apiUrl = "https://www.aladin.co.kr/ttb/api/ItemList.aspx"; // Product List API
        StringBuilder urlBuilder = new StringBuilder(apiUrl);
        urlBuilder.append("?ttbkey=").append(ttbKey);
        urlBuilder.append("&QueryType=Bestseller");
        // Only include SearchTarget if provided, otherwise default to Book
        urlBuilder.append("&SearchTarget=").append(searchTarget != null && searchTarget.length() > 0 ? searchTarget : "Book");
        urlBuilder.append("&output=js");
        urlBuilder.append("&Cover=Big");
        urlBuilder.append("&Version=20131101");
        //urlBuilder.append("&CategoryId=2105");
        // include parsed start/max
        urlBuilder.append("&Start=").append(startInt);
        urlBuilder.append("&MaxResults=").append(maxInt);
        // optional CategoryId/year/month/week
        if (categoryId != null && categoryId.matches("\\d+")) urlBuilder.append("&CategoryId=").append(categoryId);
        if (year != null && month != null && week != null && year.matches("\\d+") && month.matches("\\d+") && week.matches("\\d+")) {
            urlBuilder.append("&Year=").append(year).append("&Month=").append(month).append("&Week=").append(week);
        }

        String requestUrl = urlBuilder.toString();
        System.out.println("[알라딘API][베스트셀러] 요청 URL: " + requestUrl);

        try {
            RestTemplate restTemplate = new RestTemplate();
            restTemplate.getMessageConverters().add(0, new StringHttpMessageConverter(StandardCharsets.UTF_8));
            String result = restTemplate.getForObject(requestUrl, String.class);
            System.out.println("[알라딘API][베스트셀러] 응답 수신 (len=" + (result!=null?result.length():0) + ")");
            JSONObject json = new JSONObject(result);
            JSONArray items = json.getJSONArray("item");
            JSONArray books = new JSONArray();

            for (int i = 0; i < items.length(); i++) {
                JSONObject item = items.getJSONObject(i);
                JSONObject book = new JSONObject();
                String title = item.optString("title");
                String author = item.optString("author");
                String publisher = item.optString("publisher");
                String cover = item.optString("cover");
                String pubDate = item.optString("pubDate");
                String isbn13 = item.optString("isbn13");
                String isbn = item.optString("isbn");
                if (isbn13 != null) isbn13 = isbn13.replaceAll("[^0-9Xx]", "");
                if (isbn == null || isbn.trim().isEmpty()) {
                    if (isbn13 != null && !isbn13.trim().isEmpty()) isbn = isbn13;
                } else {
                    isbn = isbn.replaceAll("[^0-9Xx]", "");
                }
                String link = item.optString("link");
                int priceStandard = item.optInt("priceStandard", 0);
                int priceSales = item.optInt("priceSales", 0);
                String categoryName = item.optString("categoryName");
                String categoryIdStr = item.optString("categoryId");
                int customerReviewRank = item.optInt("customerReviewRank", 0);
                int salesPoint = item.optInt("salesPoint", 0);
                int itemId = item.optInt("itemId", 0);
                String mallType = item.optString("mallType");
                String description = item.optString("description");

                book.put("title", title);
                book.put("author", author);
                book.put("publisher", publisher);
                book.put("cover", cover);
                book.put("pubDate", pubDate);
                book.put("isbn", isbn);
                book.put("isbn13", isbn13);
                books.put(book);

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
                bookEntity.setCategoryId(categoryIdStr);
                bookEntity.setCustomerReviewRank(customerReviewRank);
                bookEntity.setSalesPoint(salesPoint);
                bookEntity.setItemId(itemId);
                bookEntity.setMallType(mallType);

                try {
                    aladinBookDAO.insert(bookEntity);
                } catch (com.mn.cm.dao.DuplicateIsbnException dupEx) {
                    System.out.println("[알라딘API][베스트셀러] 중복 ISBN으로 스킵: " + dupEx.getMessage());
                } catch (Exception ex) {
                    ex.printStackTrace();
                }
            }

            // DB fallback: if no items returned and start <= 490, query local DB
            if (items.length() == 0) {
                System.out.println("[알라딘API][베스트셀러] API 반환 아이템이 없습니다. DB에서 대체 조회 시도합니다.");
                try {
                    int startIntFallback = 1;
                    int maxIntFallback = 10;
                    try { if (start != null && start.matches("\\d+")) startIntFallback = Integer.parseInt(start); } catch (Exception e) {}
                    try { if (maxResults != null && maxResults.matches("\\d+")) maxIntFallback = Integer.parseInt(maxResults); } catch (Exception e) {}
                    // Aladin API historically limits Start to ~490; if requested start beyond that or API returned empty, use DB fallback
                    int offset = Math.max(0, startIntFallback - 1);
                    java.util.List<AladinBook> list = aladinBookDAO.selectList(offset, maxIntFallback);
                    if (list != null && !list.isEmpty()) {
                        for (AladinBook ab : list) {
                            JSONObject b = new JSONObject();
                            b.put("title", ab.getTitle());
                            b.put("author", ab.getAuthor());
                            b.put("publisher", ab.getPublisher());
                            b.put("cover", ab.getCover());
                            b.put("pubDate", ab.getPubDate());
                            b.put("isbn", ab.getIsbn());
                            b.put("isbn13", ab.getIsbn13());
                            books.put(b);
                        }
                        return books.toString();
                    } else {
                        System.out.println("[알라딘API][베스트셀러] DB에도 결과 없음");
                        return books.toString();
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                    return books.toString();
                }
            }

            return books.toString();
        } catch (Exception e) {
            System.out.println("[알라딘API][베스트셀러] 예외 발생: " + e.getMessage());
            e.printStackTrace();
            return "[]";
        }
    }

}