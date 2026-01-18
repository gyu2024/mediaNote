package com.mn.cm.model;

import java.util.Date;

public class AladinBook {
    private String isbn13;
    private String isbn;
    private String title;
    private String author;
    private String publisher;
    private String pubDate;
    private String description;
    private String cover;
    private String link;
    private int priceStandard;
    private int priceSales;
    private String categoryName;
    private String categoryId;
    private int customerReviewRank;
    private int salesPoint;
    private int itemId;
    private String mallType;
    private Date regDt;
    private Date modDt;
    // Getters and Setters
    public String getIsbn13() { return isbn13; }
    public void setIsbn13(String isbn13) { this.isbn13 = isbn13; }
    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getAuthor() { return author; }
    public void setAuthor(String author) { this.author = author; }
    public String getPublisher() { return publisher; }
    public void setPublisher(String publisher) { this.publisher = publisher; }
    public String getPubDate() { return pubDate; }
    public void setPubDate(String pubDate) { this.pubDate = pubDate; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCover() { return cover; }
    public void setCover(String cover) { this.cover = cover; }
    public String getLink() { return link; }
    public void setLink(String link) { this.link = link; }
    public int getPriceStandard() { return priceStandard; }
    public void setPriceStandard(int priceStandard) { this.priceStandard = priceStandard; }
    public int getPriceSales() { return priceSales; }
    public void setPriceSales(int priceSales) { this.priceSales = priceSales; }
    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }
    public String getCategoryId() { return categoryId; }
    public void setCategoryId(String categoryId) { this.categoryId = categoryId; }
    public int getCustomerReviewRank() { return customerReviewRank; }
    public void setCustomerReviewRank(int customerReviewRank) { this.customerReviewRank = customerReviewRank; }
    public int getSalesPoint() { return salesPoint; }
    public void setSalesPoint(int salesPoint) { this.salesPoint = salesPoint; }
    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }
    public String getMallType() { return mallType; }
    public void setMallType(String mallType) { this.mallType = mallType; }
    public Date getRegDt() { return regDt; }
    public void setRegDt(Date regDt) { this.regDt = regDt; }
    public Date getModDt() { return modDt; }
    public void setModDt(Date modDt) { this.modDt = modDt; }
}