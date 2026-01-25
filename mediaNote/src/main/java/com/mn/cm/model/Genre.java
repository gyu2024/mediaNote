package com.mn.cm.model;

public class Genre {
    private Integer genreId;
    private String genreNm;
    private String mediaType; // MOVIE or TV

    public Integer getGenreId() { return genreId; }
    public void setGenreId(Integer genreId) { this.genreId = genreId; }

    public String getGenreNm() { return genreNm; }
    public void setGenreNm(String genreNm) { this.genreNm = genreNm; }

    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }
}
