package com.mn.cm.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import com.mn.cm.dao.GenreDAO;
import com.mn.cm.model.Genre;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Iterator;

@Service
public class GenreService {

    private static final Logger logger = LoggerFactory.getLogger(GenreService.class);

    @Autowired
    private GenreDAO genreDAO;

    @Value("${tmdb.api.key:}")
    private String tmdbApiKey;

    private ObjectMapper mapper = new ObjectMapper();

    public int syncGenres(String mediaType) {
        // mediaType expected: MOVIE or TV
        if (tmdbApiKey == null || tmdbApiKey.trim().isEmpty()) {
            throw new IllegalStateException("TMDB API key not configured");
        }
        String url = null;
        if ("MOVIE".equalsIgnoreCase(mediaType)) {
            url = "https://api.themoviedb.org/3/genre/movie/list?api_key=" + tmdbApiKey + "&language=ko-KR";
        } else if ("TV".equalsIgnoreCase(mediaType)) {
            url = "https://api.themoviedb.org/3/genre/tv/list?api_key=" + tmdbApiKey + "&language=ko-KR";
        } else {
            throw new IllegalArgumentException("mediaType must be MOVIE or TV");
        }

        HttpURLConnection conn = null;
        BufferedReader reader = null;
        StringBuilder sb = new StringBuilder();
        int insertedOrUpdated = 0;
        try {
            URL u = new URL(url);
            conn = (HttpURLConnection) u.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            int status = conn.getResponseCode();
            reader = new BufferedReader(new InputStreamReader((status>=200 && status<400)?conn.getInputStream():conn.getErrorStream(), "UTF-8"));
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append('\n');
            String raw = sb.toString();
            JsonNode root = mapper.readTree(raw);
            JsonNode genres = root.has("genres") ? root.get("genres") : null;
            if (genres != null && genres.isArray()) {
                // Optionally clear existing for this mediaType first
                genreDAO.deleteAllForMedia(mediaType.toUpperCase());
                Iterator<JsonNode> it = genres.elements();
                while (it.hasNext()) {
                    JsonNode g = it.next();
                    try {
                        Genre ge = new Genre();
                        ge.setGenreId(g.has("id")? g.get("id").asInt() : null);
                        ge.setGenreNm(g.has("name")? g.get("name").asText() : "");
                        ge.setMediaType(mediaType.toUpperCase());
                        genreDAO.upsertGenre(ge);
                        insertedOrUpdated++;
                    } catch (Exception e) {
                        logger.warn("Failed to upsert genre {}: {}", g, e.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            logger.error("Failed to sync genres for {}", mediaType, e);
            throw new RuntimeException(e);
        } finally {
            try { if (reader != null) reader.close(); } catch (Exception ignored) {}
            if (conn != null) conn.disconnect();
        }
        return insertedOrUpdated;
    }
}
