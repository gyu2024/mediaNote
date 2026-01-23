package com.mn.cm.model;

import java.util.Date;

public class Movie {
    private Integer mvId; // MV_ID
    private Integer tmdbId; // TMDB movie id (optional)
    private String title;
    private String originalTitle;
    private String overview;
    private Date releaseDate;
    private Double voteAverage;
    private Integer voteCount;
    private Double popularity;
    private String posterPath;
    private String backdropPath;
    private String originalLang;
    private Boolean isAdult;
    private String genreIds; // comma-separated
    private java.util.Date regDt;
    private java.util.Date modDt;

    // getters and setters
    public Integer getMvId() { return mvId; }
    public void setMvId(Integer mvId) { this.mvId = mvId; }
    public Integer getTmdbId() { return tmdbId; }
    public void setTmdbId(Integer tmdbId) { this.tmdbId = tmdbId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getOriginalTitle() { return originalTitle; }
    public void setOriginalTitle(String originalTitle) { this.originalTitle = originalTitle; }
    public String getOverview() { return overview; }
    public void setOverview(String overview) { this.overview = overview; }
    public Date getReleaseDate() { return releaseDate; }
    public void setReleaseDate(Date releaseDate) { this.releaseDate = releaseDate; }
    public Double getVoteAverage() { return voteAverage; }
    public void setVoteAverage(Double voteAverage) { this.voteAverage = voteAverage; }
    public Integer getVoteCount() { return voteCount; }
    public void setVoteCount(Integer voteCount) { this.voteCount = voteCount; }
    public Double getPopularity() { return popularity; }
    public void setPopularity(Double popularity) { this.popularity = popularity; }
    public String getPosterPath() { return posterPath; }
    public void setPosterPath(String posterPath) { this.posterPath = posterPath; }
    public String getBackdropPath() { return backdropPath; }
    public void setBackdropPath(String backdropPath) { this.backdropPath = backdropPath; }
    public String getOriginalLang() { return originalLang; }
    public void setOriginalLang(String originalLang) { this.originalLang = originalLang; }
    public Boolean getIsAdult() { return isAdult; }
    public void setIsAdult(Boolean isAdult) { this.isAdult = isAdult; }
    public String getGenreIds() { return genreIds; }
    public void setGenreIds(String genreIds) { this.genreIds = genreIds; }
    public java.util.Date getRegDt() { return regDt; }
    public void setRegDt(java.util.Date regDt) { this.regDt = regDt; }
    public java.util.Date getModDt() { return modDt; }
    public void setModDt(java.util.Date modDt) { this.modDt = modDt; }
}
