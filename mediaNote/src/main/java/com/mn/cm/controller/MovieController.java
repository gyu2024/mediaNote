package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Autowired;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URLEncoder;
import java.net.URL;

import com.mn.cm.service.MovieService;
import com.mn.cm.model.Movie;
import jakarta.servlet.http.HttpServletRequest;
import com.mn.cm.dao.MovieReviewDAO;
import com.mn.cm.model.User;

@Controller
public class MovieController {

    private static final Logger logger = LoggerFactory.getLogger(MovieController.class);

    @Value("${tmdb.api.key:}")
    private String tmdbApiKey;

    @Autowired
    private MovieService movieService;
    @Autowired
    private MovieReviewDAO movieReviewDAO;

    // Proxy endpoint to call TMDB Search API server-side so API key is not exposed to clients
    @GetMapping(value = "/movie/search", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public String searchMovie(@RequestParam(name = "query") String query,
                              @RequestParam(name = "pretty", required = false, defaultValue = "false") boolean pretty,
                              @RequestParam(name = "saveMissing", required = false, defaultValue = "true") boolean saveMissing,
                              HttpServletRequest request) throws IOException {
        if (tmdbApiKey == null || tmdbApiKey.trim().isEmpty()) {
            // return a minimal error JSON so client can show a friendly message
            return "{ \"status\": \"ERR\", \"message\": \"TMDB API key not configured on server\" }";
        }
        String encoded = URLEncoder.encode(query == null ? "" : query, "UTF-8");
        String apiUrl = "https://api.themoviedb.org/3/search/movie?api_key=" + tmdbApiKey + "&query=" + encoded + "&language=ko-KR&page=1&include_adult=false";

        HttpURLConnection conn = null;
        BufferedReader reader = null;
        StringBuilder sb = new StringBuilder();
        try {
            URL url = new URL(apiUrl);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            int status = conn.getResponseCode();
            reader = new BufferedReader(new InputStreamReader(
                    status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8"));

            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append('\n');

            String raw = sb.toString();

            // Log a short preview for debugging
            try {
                logger.info("TMDB response for query='{}' (status={}): {}", query, status, raw.replaceAll("\n", " "));
            } catch (Exception logEx) { logger.debug("Failed to create TMDB preview log", logEx); }

            // Parse TMDB raw JSON once and create a sanitized copy for returning to clients
            ObjectMapper mapper = new ObjectMapper();
            com.fasterxml.jackson.databind.JsonNode sanitizedRoot = null;
            try {
                com.fasterxml.jackson.databind.JsonNode parsed = mapper.readTree(raw);
                if (parsed != null && parsed.has("results") && parsed.get("results").isArray()) {
                    // deep-copy by converting to ObjectNode so we can mutate safely
                    sanitizedRoot = parsed.deepCopy();
                    com.fasterxml.jackson.databind.JsonNode results = sanitizedRoot.get("results");
                    for (int i = 0; i < results.size(); i++) {
                        com.fasterxml.jackson.databind.JsonNode item = results.get(i);
                        if (item != null && item.isObject()) {
                            ((com.fasterxml.jackson.databind.node.ObjectNode) item).remove("overview");
                        }
                    }
                } else {
                    // parsed but no results array: still keep sanitizedRoot as parsed without modifications
                    sanitizedRoot = parsed;
                }
            } catch (Exception e) {
                // parsing failed; sanitizedRoot stays null and we'll fall back to raw
                logger.debug("Failed to parse TMDB JSON for sanitization", e);
            }

            // Attach user-specific flags (userHasReview, userRead) to results if logged in
            try {
                User user = null;
                try { user = (User) request.getSession().getAttribute("USER_SESSION"); } catch (Exception ignore) {}
                String userId = (user != null ? String.valueOf(user.getId()) : null);
                if (userId != null && sanitizedRoot != null && sanitizedRoot.has("results") && sanitizedRoot.get("results").isArray()) {
                    java.util.List<Integer> mvIds = new java.util.ArrayList<>();
                    com.fasterxml.jackson.databind.JsonNode results = sanitizedRoot.get("results");
                    for (int i = 0; i < results.size(); i++) {
                        com.fasterxml.jackson.databind.JsonNode it = results.get(i);
                        try { if (it.has("id") && !it.get("id").isNull()) mvIds.add(it.get("id").asInt()); } catch (Exception ignore) {}
                    }
                    if (!mvIds.isEmpty()) {
                        java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                        java.util.Map<String, java.util.Map<String,Object>> byId = new java.util.HashMap<>();
                        for (java.util.Map<String,Object> r : rows) {
                            if (r == null) continue;
                            String k = null;
                            try {
                                if (r.get("MV_ID") != null) k = String.valueOf(r.get("MV_ID"));
                                else if (r.get("mvId") != null) k = String.valueOf(r.get("mvId"));
                                else if (r.get("mv_id") != null) k = String.valueOf(r.get("mv_id"));
                            } catch (Exception ignore) {}
                            if (k != null) byId.put(k, r);
                        }
                        for (int i = 0; i < results.size(); i++) {
                            com.fasterxml.jackson.databind.JsonNode it = results.get(i);
                            if (it == null || !it.isObject()) continue;
                            String key = null;
                            try { key = String.valueOf(it.get("id").asInt()); } catch (Exception ignore) {}
                            java.util.Map<String,Object> st = (key != null ? byId.get(key) : null);
                            boolean hasReview = false;
                            boolean hasRead = false;
                            if (st != null) {
                                Object ratingObj = (st.get("RATING") != null ? st.get("RATING") : st.get("rating"));
                                Object cmntObj = (st.get("CMNT") != null ? st.get("CMNT") : (st.get("cmnt") != null ? st.get("cmnt") : st.get("comment")));
                                Object reviewTextObj = (st.get("REVIEW_TEXT") != null ? st.get("REVIEW_TEXT") : (st.get("reviewText") != null ? st.get("reviewText") : st.get("text")));
                                if (ratingObj != null && String.valueOf(ratingObj).trim().length() > 0) hasReview = true;
                                if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                                Object ryn = (st.get("READ_YN") != null ? st.get("READ_YN") : st.get("readYn"));
                                if (ryn != null) {
                                    String s = String.valueOf(ryn).trim();
                                    if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) hasRead = true;
                                }
                            }
                            ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userHasReview", hasReview);
                            ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userRead", hasRead);
                        }
                    }
                }
            } catch (Exception e) { logger.debug("Failed to attach user flags to TMDB results", e); }

            if (pretty) {
                try {
                    if (sanitizedRoot != null) {
                        return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(sanitizedRoot);
                    }
                    // fallback to pretty printing the raw string
                    com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(raw);
                    // Attach flags for pretty fallback too
                    try {
                        User user = null;
                        try { user = (User) request.getSession().getAttribute("USER_SESSION"); } catch (Exception ignore) {}
                        String userId = (user != null ? String.valueOf(user.getId()) : null);
                        if (userId != null && root != null && root.has("results") && root.get("results").isArray()) {
                            java.util.List<Integer> mvIds = new java.util.ArrayList<>();
                            com.fasterxml.jackson.databind.JsonNode results = root.get("results");
                            for (int i = 0; i < results.size(); i++) { try { if (results.get(i).has("id")) mvIds.add(results.get(i).get("id").asInt()); } catch(Exception ignore){} }
                            if (!mvIds.isEmpty()) {
                                java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                                java.util.Map<String, java.util.Map<String,Object>> byId = new java.util.HashMap<>();
                                for (java.util.Map<String,Object> r : rows) { if (r == null) continue; String k=null; if (r.get("MV_ID")!=null) k=String.valueOf(r.get("MV_ID")); else if (r.get("mvId")!=null) k=String.valueOf(r.get("mvId")); else if (r.get("mv_id")!=null) k=String.valueOf(r.get("mv_id")); if (k!=null) byId.put(k, r);}    
                                for (int i = 0; i < results.size(); i++) {
                                    com.fasterxml.jackson.databind.JsonNode it = results.get(i);
                                    if (it == null || !it.isObject()) continue;
                                    String key = null; try { key = String.valueOf(it.get("id").asInt()); } catch(Exception ignore){}
                                    java.util.Map<String,Object> st = (key != null ? byId.get(key) : null);
                                    boolean hasReview=false, hasRead=false;
                                    if (st != null) {
                                        Object ratingObj = (st.get("RATING") != null ? st.get("RATING") : st.get("rating"));
                                        Object cmntObj = (st.get("CMNT") != null ? st.get("CMNT") : (st.get("cmnt") != null ? st.get("cmnt") : st.get("comment")));
                                        Object reviewTextObj = (st.get("REVIEW_TEXT") != null ? st.get("REVIEW_TEXT") : (st.get("reviewText") != null ? st.get("reviewText") : st.get("text")));
                                        if (ratingObj != null && String.valueOf(ratingObj).trim().length() > 0) hasReview = true;
                                        if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                        if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                                        Object ryn = (st.get("READ_YN") != null ? st.get("READ_YN") : st.get("readYn"));
                                        if (ryn != null) { String s = String.valueOf(ryn).trim(); if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) hasRead = true; }
                                    }
                                    ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userHasReview", hasReview);
                                    ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userRead", hasRead);
                                }
                            }
                        }
                    } catch (Exception ignore) {}
                    String prettyJson = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(root);
                    return prettyJson;
                } catch (Exception pe) {
                    logger.warn("Failed to pretty-print TMDB response", pe);
                    // fall back to raw
                    return raw;
                }
            }

            // If requested, ensure movies from search results are saved to DB
            if (saveMissing) {
                try {
                    int inserted = movieService.ensureMoviesSavedFromTmdbJson(raw);
                    // prefer returning sanitized JSON to clients (without overview)
                    try {
                        if (sanitizedRoot != null && sanitizedRoot.isObject()) {
                            ((com.fasterxml.jackson.databind.node.ObjectNode) sanitizedRoot).put("_inserted", inserted);
                            // Attach user flags again here to be safe before returning
                            try {
                                User user = null; try { user = (User) request.getSession().getAttribute("USER_SESSION"); } catch(Exception ignore){}
                                String userId = (user != null ? String.valueOf(user.getId()) : null);
                                if (userId != null && sanitizedRoot.has("results") && sanitizedRoot.get("results").isArray()) {
                                    java.util.List<Integer> mvIds = new java.util.ArrayList<>();
                                    com.fasterxml.jackson.databind.JsonNode results = sanitizedRoot.get("results");
                                    for (int i = 0; i < results.size(); i++) { try { if (results.get(i).has("id")) mvIds.add(results.get(i).get("id").asInt()); } catch(Exception ignore){} }
                                    if (!mvIds.isEmpty()) {
                                        java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                                        java.util.Map<String, java.util.Map<String,Object>> byId = new java.util.HashMap<>();
                                        for (java.util.Map<String,Object> r : rows) { if (r == null) continue; String k=null; if (r.get("MV_ID")!=null) k=String.valueOf(r.get("MV_ID")); else if (r.get("mvId")!=null) k=String.valueOf(r.get("mvId")); else if (r.get("mv_id")!=null) k=String.valueOf(r.get("mv_id")); if (k!=null) byId.put(k, r);}    
                                        for (int i = 0; i < results.size(); i++) {
                                            com.fasterxml.jackson.databind.JsonNode it = results.get(i);
                                            if (it == null || !it.isObject()) continue;
                                            String key = null; try { key = String.valueOf(it.get("id").asInt()); } catch(Exception ignore){}
                                            java.util.Map<String,Object> st = (key != null ? byId.get(key) : null);
                                            boolean hasReview=false, hasRead=false;
                                            if (st != null) {
                                                Object ratingObj = (st.get("RATING") != null ? st.get("RATING") : st.get("rating"));
                                                Object cmntObj = (st.get("CMNT") != null ? st.get("CMNT") : (st.get("cmnt") != null ? st.get("cmnt") : st.get("comment")));
                                                Object reviewTextObj = (st.get("REVIEW_TEXT") != null ? st.get("REVIEW_TEXT") : (st.get("reviewText") != null ? st.get("reviewText") : st.get("text")));
                                                if (ratingObj != null && String.valueOf(ratingObj).trim().length() > 0) hasReview = true;
                                                if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                                if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                                                Object ryn = (st.get("READ_YN") != null ? st.get("READ_YN") : st.get("readYn"));
                                                if (ryn != null) { String s = String.valueOf(ryn).trim(); if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) hasRead = true; }
                                            }
                                            ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userHasReview", hasReview);
                                            ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userRead", hasRead);
                                        }
                                    }
                                }
                            } catch (Exception ignore) {}
                            return mapper.writeValueAsString(sanitizedRoot);
                        } else {
                            // as a fallback, parse raw and attach _inserted then remove overview fields if possible
                            com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(raw);
                            if (root != null && root.isObject()) {
                                ((com.fasterxml.jackson.databind.node.ObjectNode) root).put("_inserted", inserted);
                                // remove overview fields from results if any
                                if (root.has("results") && root.get("results").isArray()) {
                                    for (com.fasterxml.jackson.databind.JsonNode it : root.get("results")) {
                                        if (it != null && it.isObject()) ((com.fasterxml.jackson.databind.node.ObjectNode) it).remove("overview");
                                    }
                                }
                                // Attach flags for fallback root
                                try {
                                    User user = null; try { user = (User) request.getSession().getAttribute("USER_SESSION"); } catch(Exception ignore){}
                                    String userId = (user != null ? String.valueOf(user.getId()) : null);
                                    if (userId != null && root.has("results") && root.get("results").isArray()) {
                                        java.util.List<Integer> mvIds = new java.util.ArrayList<>();
                                        com.fasterxml.jackson.databind.JsonNode results = root.get("results");
                                        for (int i = 0; i < results.size(); i++) { try { if (results.get(i).has("id")) mvIds.add(results.get(i).get("id").asInt()); } catch(Exception ignore){} }
                                        if (!mvIds.isEmpty()) {
                                            java.util.List<java.util.Map<String,Object>> rows = movieReviewDAO.selectStatuses(userId, mvIds);
                                            java.util.Map<String, java.util.Map<String,Object>> byId = new java.util.HashMap<>();
                                            for (java.util.Map<String,Object> r : rows) { if (r == null) continue; String k=null; if (r.get("MV_ID")!=null) k=String.valueOf(r.get("MV_ID")); else if (r.get("mvId")!=null) k=String.valueOf(r.get("mvId")); else if (r.get("mv_id")!=null) k=String.valueOf(r.get("mv_id")); if (k!=null) byId.put(k, r);}    
                                            for (int i = 0; i < results.size(); i++) {
                                                com.fasterxml.jackson.databind.JsonNode it = results.get(i);
                                                if (it == null || !it.isObject()) continue;
                                                String key = null; try { key = String.valueOf(it.get("id").asInt()); } catch(Exception ignore){}
                                                java.util.Map<String,Object> st = (key != null ? byId.get(key) : null);
                                                boolean hasReview=false, hasRead=false;
                                                if (st != null) {
                                                    Object ratingObj = (st.get("RATING") != null ? st.get("RATING") : st.get("rating"));
                                                    Object cmntObj = (st.get("CMNT") != null ? st.get("CMNT") : (st.get("cmnt") != null ? st.get("cmnt") : st.get("comment")));
                                                    Object reviewTextObj = (st.get("REVIEW_TEXT") != null ? st.get("REVIEW_TEXT") : (st.get("reviewText") != null ? st.get("reviewText") : st.get("text")));
                                                    if (ratingObj != null && String.valueOf(ratingObj).trim().length() > 0) hasReview = true;
                                                    if (!hasReview && cmntObj != null && String.valueOf(cmntObj).trim().length() > 0) hasReview = true;
                                                    if (!hasReview && reviewTextObj != null && String.valueOf(reviewTextObj).trim().length() > 0) hasReview = true;
                                                    Object ryn = (st.get("READ_YN") != null ? st.get("READ_YN") : st.get("readYn"));
                                                    if (ryn != null) { String s = String.valueOf(ryn).trim(); if ("Y".equalsIgnoreCase(s) || "1".equals(s) || "true".equalsIgnoreCase(s)) hasRead = true; }
                                                }
                                                ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userHasReview", hasReview);
                                                ((com.fasterxml.jackson.databind.node.ObjectNode) it).put("userRead", hasRead);
                                            }
                                        }
                                    }
                                } catch (Exception ignore) {}
                                return mapper.writeValueAsString(root);
                            }
                        }
                    } catch (Exception e) {
                        logger.warn("Failed to attach inserted-count to sanitized TMDB JSON", e);
                        // ignore and return raw
                    }
                } catch (Exception e) {
                    logger.warn("Failed to save movies from TMDB search results", e);
                }
            }

            // If we reach here, return sanitized JSON if available, otherwise raw
            try {
                if (sanitizedRoot != null) return mapper.writeValueAsString(sanitizedRoot);
            } catch (Exception e) { /* ignore */ }
            return raw;
        } catch (IOException e) {
            logger.error("Error contacting TMDB for query='{}': {}", query, e.getMessage());
            // return simple error JSON
            return "{ \"status\": \"ERR\", \"message\": \"Failed to contact TMDB: " + e.getMessage() + "\" }";
        } finally {
            try { if (reader != null) reader.close(); } catch (Exception ignored) {}
            if (conn != null) conn.disconnect();
        }
    }

    // New endpoint to fetch a single movie from TMDB by id and persist it to MN_MV_MST
    @GetMapping(value = "/movie/saveFromTmdb", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public String saveFromTmdb(@RequestParam(name = "tmdbId", required = false) Integer tmdbId,
                               @RequestParam(name = "rawJson", required = false) String rawJson) {
        try {
            String jsonPayload = rawJson;
            // If no raw JSON provided, fetch from TMDB by id
            if ((jsonPayload == null || jsonPayload.trim().length() == 0) && tmdbId != null) {
                if (tmdbApiKey == null || tmdbApiKey.trim().isEmpty()) {
                    return "{ \"status\": \"ERR\", \"message\": \"TMDB API key not configured on server\" }";
                }
                String apiUrl = "https://api.themoviedb.org/3/movie/" + tmdbId + "?api_key=" + tmdbApiKey + "&language=ko-KR";
                HttpURLConnection conn = null;
                BufferedReader reader = null;
                StringBuilder sb = new StringBuilder();
                try {
                    URL url = new URL(apiUrl);
                    conn = (HttpURLConnection) url.openConnection();
                    conn.setRequestMethod("GET");
                    conn.setConnectTimeout(5000);
                    conn.setReadTimeout(5000);
                    int status = conn.getResponseCode();
                    reader = new BufferedReader(new InputStreamReader(
                            status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8"));
                    String line;
                    while ((line = reader.readLine()) != null) sb.append(line).append('\n');
                    jsonPayload = sb.toString();
                } finally {
                    try { if (reader != null) reader.close(); } catch (Exception ignored) {}
                    if (conn != null) conn.disconnect();
                }
            }

            if (jsonPayload == null || jsonPayload.trim().length() == 0) {
                return "{ \"status\": \"ERR\", \"message\": \"No movie data provided or found\" }";
            }

            // Parse JSON and map to Movie model
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(jsonPayload);
            Movie m = new Movie();
            try { if (root.has("id")) { int apiId = root.get("id").asInt(); m.setTmdbId(apiId); m.setMvId(apiId); } } catch(Exception e){}
            try { if (root.has("title")) m.setTitle(root.get("title").asText()); } catch(Exception e){}
            try { if (root.has("original_title")) m.setOriginalTitle(root.get("original_title").asText()); } catch(Exception e){}
            try { if (root.has("overview")) m.setOverview(root.get("overview").asText()); } catch(Exception e){}
            try { if (root.has("release_date") && !root.get("release_date").isNull() && root.get("release_date").asText().length()>0) m.setReleaseDate(java.sql.Date.valueOf(root.get("release_date").asText())); } catch(Exception e){}
            try { if (root.has("vote_average")) m.setVoteAverage(root.get("vote_average").asDouble()); } catch(Exception e){}
            try { if (root.has("vote_count")) m.setVoteCount(root.get("vote_count").asInt()); } catch(Exception e){}
            try { if (root.has("popularity")) m.setPopularity(root.get("popularity").asDouble()); } catch(Exception e){}
            try { if (root.has("poster_path")) m.setPosterPath(root.get("poster_path").asText()); } catch(Exception e){}
            try { if (root.has("backdrop_path")) m.setBackdropPath(root.get("backdrop_path").asText()); } catch(Exception e){}
            try { if (root.has("original_language")) m.setOriginalLang(root.get("original_language").asText()); } catch(Exception e){}
            try { if (root.has("adult")) m.setIsAdult(root.get("adult").asBoolean()); } catch(Exception e){}
            // genre ids: if genres array contains objects with id, join them
            try {
                if (root.has("genres") && root.get("genres").isArray()) {
                    StringBuilder gids = new StringBuilder();
                    for (JsonNode g : root.get("genres")) {
                        if (g.has("id")) {
                            if (gids.length()>0) gids.append(',');
                            gids.append(g.get("id").asText());
                        }
                    }
                    m.setGenreIds(gids.toString());
                } else if (root.has("genre_ids") && root.get("genre_ids").isArray()) {
                    StringBuilder gids = new StringBuilder();
                    for (JsonNode idn : root.get("genre_ids")) { if (gids.length()>0) gids.append(','); gids.append(idn.asText()); }
                    m.setGenreIds(gids.toString());
                }
            } catch(Exception e){ }

            // After mapping basic movie fields, attempt to fetch credits and save them into the Movie model
            // Credits enrichment disabled to avoid slow list/save operations

            // Check if movie exists in DB (prefer title + release_date, fallback to title).
            Movie existing = null;
            try {
                if (m.getTitle() != null && m.getReleaseDate() != null) {
                    existing = movieService.findByTitleAndRelease(m.getTitle(), new java.sql.Date(m.getReleaseDate().getTime()));
                }
                if (existing == null && m.getTitle() != null) {
                    existing = movieService.findByTitle(m.getTitle());
                }
            } catch (Exception e) { logger.warn("DB check failed", e); }

            if (existing != null) {
                // return existing movie info (minimal)
                return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(existing);
            }

            // Save via service
            int inserted = movieService.saveMovie(m);
            return "{ \"status\": \"OK\", \"inserted\": " + inserted + " }";
        } catch (Exception e) {
            logger.error("Failed to save movie from TMDB", e);
            return "{ \"status\": \"ERR\", \"message\": \"" + e.getMessage() + "\" }";
        }
    }

    // New: fetch credits (director + cast) from TMDB for a given tmdbId and return sanitized JSON
    @GetMapping(value = "/movie/credits", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public String fetchMovieCredits(@RequestParam(name = "tmdbId") Integer tmdbId) {
        if (tmdbApiKey == null || tmdbApiKey.trim().isEmpty()) {
            return "{ \"status\": \"ERR\", \"message\": \"TMDB API key not configured on server\" }";
        }
        if (tmdbId == null) {
            return "{ \"status\": \"ERR\", \"message\": \"Missing tmdbId parameter\" }";
        }
        String apiUrl = "https://api.themoviedb.org/3/movie/" + tmdbId + "/credits?api_key=" + tmdbApiKey + "&language=ko-KR";
        HttpURLConnection conn = null;
        BufferedReader reader = null;
        StringBuilder sb = new StringBuilder();
        ObjectMapper mapper = new ObjectMapper();
        try {
            URL url = new URL(apiUrl);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            int status = conn.getResponseCode();
            reader = new BufferedReader(new InputStreamReader(
                    status >= 200 && status < 400 ? conn.getInputStream() : conn.getErrorStream(), "UTF-8"));
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append('\n');
            String raw = sb.toString();
            // parse
            com.fasterxml.jackson.databind.JsonNode root = null;
            try { root = mapper.readTree(raw); } catch (Exception e) { logger.debug("Failed to parse TMDB credits JSON", e); }
            com.fasterxml.jackson.databind.node.ObjectNode out = mapper.createObjectNode();
            if (root == null) {
                out.put("status", "ERR");
                out.put("message", "Failed to parse TMDB response");
                return mapper.writeValueAsString(out);
            }
            // director(s)
            com.fasterxml.jackson.databind.node.ArrayNode directors = mapper.createArrayNode();
            if (root.has("crew") && root.get("crew").isArray()) {
                for (com.fasterxml.jackson.databind.JsonNode c : root.get("crew")) {
                    try {
                        String job = c.has("job") ? c.get("job").asText("") : "";
                        if (job != null && job.toLowerCase().contains("director")) {
                            com.fasterxml.jackson.databind.node.ObjectNode d = mapper.createObjectNode();
                            if (c.has("id")) d.put("id", c.get("id").asInt());
                            if (c.has("name")) d.put("name", c.get("name").asText(""));
                            if (c.has("department")) d.put("department", c.get("department").asText(""));
                            if (c.has("job")) d.put("job", c.get("job").asText(""));
                            if (c.has("profile_path") && !c.get("profile_path").isNull()) d.put("profile_path", c.get("profile_path").asText(""));
                            directors.add(d);
                        }
                    } catch (Exception ignore) {}
                }
            }
            // cast (take first up to 12 ordered by 'order' or API order)
            com.fasterxml.jackson.databind.node.ArrayNode cast = mapper.createArrayNode();
            if (root.has("cast") && root.get("cast").isArray()) {
                int taken = 0;
                for (com.fasterxml.jackson.databind.JsonNode cc : root.get("cast")) {
                    if (taken >= 12) break;
                    try {
                        com.fasterxml.jackson.databind.node.ObjectNode a = mapper.createObjectNode();
                        if (cc.has("id")) a.put("id", cc.get("id").asInt());
                        if (cc.has("name")) a.put("name", cc.get("name").asText(""));
                        if (cc.has("character")) a.put("character", cc.get("character").asText(""));
                        if (cc.has("order")) a.put("order", cc.get("order").asInt());
                        if (cc.has("profile_path") && !cc.get("profile_path").isNull()) a.put("profile_path", cc.get("profile_path").asText(""));
                        cast.add(a);
                        taken++;
                    } catch (Exception ignore) {}
                }
            }
            out.put("status", "OK");
            out.set("directors", directors);
            out.set("cast", cast);
            // include raw credits optionally for debugging
            // out.set("raw", root);
            return mapper.writeValueAsString(out);
        } catch (IOException e) {
            logger.error("Error contacting TMDB credits for tmdbId={}: {}", tmdbId, e.getMessage());
            try {
                return mapper.writeValueAsString(mapper.createObjectNode().put("status","ERR").put("message","Failed to contact TMDB: " + e.getMessage()));
            } catch (Exception ee) { return "{ \"status\": \"ERR\", \"message\": \"Unexpected error\" }"; }
        } finally {
            try { if (reader != null) reader.close(); } catch (Exception ignored) {}
            if (conn != null) conn.disconnect();
        }
    }
}
