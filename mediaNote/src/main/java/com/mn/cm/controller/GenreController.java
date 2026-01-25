package com.mn.cm.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

import com.mn.cm.service.GenreService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@RestController
public class GenreController {

    private static final Logger logger = LoggerFactory.getLogger(GenreController.class);

    @Autowired
    private GenreService genreService;

    @GetMapping(value = "/genre/sync", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public String syncGenres(@RequestParam(name = "mediaType") String mediaType) {
        try {
            int cnt = genreService.syncGenres(mediaType);
            return "{ \"status\": \"OK\", \"count\": " + cnt + " }";
        } catch (Exception e) {
            logger.error("Genre sync failed for {}", mediaType, e);
            return "{ \"status\": \"ERR\", \"message\": \"" + e.getMessage() + "\" }";
        }
    }
}
