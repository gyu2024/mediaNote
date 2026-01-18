package com.mn.cm.model;

import java.util.Date;

public class UserMaster {
    private String userId; // USER_ID (kakao unique id)
    private String email;
    private String nickname;
    private String profileImage;
    private Date regDt;
    private Date modDt;
    private Date lastLogin;

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getNickname() { return nickname; }
    public void setNickname(String nickname) { this.nickname = nickname; }

    public String getProfileImage() { return profileImage; }
    public void setProfileImage(String profileImage) { this.profileImage = profileImage; }

    public Date getRegDt() { return regDt; }
    public void setRegDt(Date regDt) { this.regDt = regDt; }

    public Date getModDt() { return modDt; }
    public void setModDt(Date modDt) { this.modDt = modDt; }

    public Date getLastLogin() { return lastLogin; }
    public void setLastLogin(Date lastLogin) { this.lastLogin = lastLogin; }
}