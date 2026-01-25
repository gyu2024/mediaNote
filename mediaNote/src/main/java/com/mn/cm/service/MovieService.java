package com.mn.cm.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.mn.cm.dao.MovieDAO;
import com.mn.cm.model.Movie;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

@Service
public class MovieService {

    private static final Logger logger = LoggerFactory.getLogger(MovieService.class);

    @Autowired
    private MovieDAO movieDAO;

    @Value("${tmdb.api.key:}")
    private String tmdbApiKey;

    public int saveMovie(Movie m) {
        return movieDAO.insertMovie(m);
    }

    public Movie findByMvId(int mvId) {
        return movieDAO.selectByMvId(mvId);
    }

    public Movie findByTitleAndRelease(String title, java.sql.Date releaseDate) {
        return movieDAO.selectByTitleAndRelease(title, releaseDate);
    }

    public Movie findByTitle(String title) {
        return movieDAO.selectByTitle(title);
    }

    /**
     * Check existence by title+release (preferred), fall back to title-only. If exists, return it; otherwise insert and return null.
     * Returns existing Movie if found, or null if newly inserted (caller can assume saved).
     */
    public Movie ensureMovieSaved(Movie m) {
        Movie existing = null;
        try {
            // If API provided an MV_ID (we now set mvId from TMDB id), check by mvId first to avoid duplicates
            if (m.getMvId() != null) {
                existing = findByMvId(m.getMvId());
            }
            if (m.getTitle() != null && m.getReleaseDate() != null) {
                existing = existing == null ? findByTitleAndRelease(m.getTitle(), new java.sql.Date(m.getReleaseDate().getTime())) : existing;
            }
            if (existing == null && m.getTitle() != null) {
                existing = findByTitle(m.getTitle());
            }
            if (existing != null) return existing;
            saveMovie(m);
            return null;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * Parse a TMDB search JSON payload and ensure each movie in `results` exists in DB.
     * Returns number of newly inserted records.
     */
    public int ensureMoviesSavedFromTmdbJson(String tmdbSearchJson) {
        if (tmdbSearchJson == null || tmdbSearchJson.trim().isEmpty()) return 0;
        int inserted = 0;
        ObjectMapper mapper = new ObjectMapper();
        try {
            JsonNode root = mapper.readTree(tmdbSearchJson);
            if (root == null) return 0;
            JsonNode results = root.has("results") ? root.get("results") : null;
            if (results != null && results.isArray()) {
                for (JsonNode item : results) {
                    try {
                        Movie m = new Movie();
                        try { if (item.has("id")) { int apiId = item.get("id").asInt(); m.setTmdbId(apiId); m.setMvId(apiId); } } catch(Exception e){}
                        try { if (item.has("title")) m.setTitle(item.get("title").asText()); } catch(Exception e){}
                        try { if (item.has("original_title")) m.setOriginalTitle(item.get("original_title").asText()); } catch(Exception e){}
                        try { if (item.has("overview")) m.setOverview(item.get("overview").asText()); } catch(Exception e){}
                        try { if (item.has("release_date") && !item.get("release_date").isNull() && item.get("release_date").asText().length()>0) m.setReleaseDate(java.sql.Date.valueOf(item.get("release_date").asText())); } catch(Exception e){}
                        try { if (item.has("vote_average")) m.setVoteAverage(item.get("vote_average").asDouble()); } catch(Exception e){}
                        try { if (item.has("vote_count")) m.setVoteCount(item.get("vote_count").asInt()); } catch(Exception e){}
                        try { if (item.has("popularity")) m.setPopularity(item.get("popularity").asDouble()); } catch(Exception e){}
                        try { if (item.has("poster_path")) m.setPosterPath(item.get("poster_path").asText()); } catch(Exception e){}
                        try { if (item.has("backdrop_path")) m.setBackdropPath(item.get("backdrop_path").asText()); } catch(Exception e){}
                        try { if (item.has("original_language")) m.setOriginalLang(item.get("original_language").asText()); } catch(Exception e){}
                        try { if (item.has("adult")) m.setIsAdult(item.get("adult").asBoolean()); } catch(Exception e){}
                        try {
                            if (item.has("genre_ids") && item.get("genre_ids").isArray()) {
                                StringBuilder gids = new StringBuilder();
                                for (JsonNode idn : item.get("genre_ids")) { if (gids.length()>0) gids.append(','); gids.append(idn.asText()); }
                                m.setGenreIds(gids.toString());
                            }
                        } catch(Exception e){}

                        // Attempt to fetch credits for this tmdbId so we also persist CASTS and CREDITS
                        // Credits enrichment disabled to keep search/save fast

                        Movie existed = ensureMovieSaved(m);
                        if (existed == null) inserted++;
                    } catch (Exception itemEx) {
                        logger.warn("Failed to process TMDB item while saving", itemEx);
                        // continue with next item
                    }
                }
            }
        } catch (Exception e) {
            logger.warn("Failed to parse TMDB search JSON for saving movies", e);
        }
        return inserted;
    }
}