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

@Controller
public class MovieController {

    private static final Logger logger = LoggerFactory.getLogger(MovieController.class);

    @Value("${tmdb.api.key:}")
    private String tmdbApiKey;

    @Autowired
    private MovieService movieService;

    // Proxy endpoint to call TMDB Search API server-side so API key is not exposed to clients
    @GetMapping(value = "/movie/search", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public String searchMovie(@RequestParam(name = "query") String query,
                              @RequestParam(name = "pretty", required = false, defaultValue = "false") boolean pretty,
                              @RequestParam(name = "saveMissing", required = false, defaultValue = "true") boolean saveMissing) throws IOException {
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

            if (pretty) {
                try {
                    if (sanitizedRoot != null) {
                        return mapper.writerWithDefaultPrettyPrinter().writeValueAsString(sanitizedRoot);
                    }
                    // fallback to pretty printing the raw string
                    com.fasterxml.jackson.databind.JsonNode root = mapper.readTree(raw);
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
}