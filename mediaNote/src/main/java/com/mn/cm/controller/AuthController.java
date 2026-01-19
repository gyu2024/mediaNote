package com.mn.cm.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.servlet.view.RedirectView;
import com.mn.cm.model.User;
import com.mn.cm.model.UserMaster;
import com.mn.cm.dao.UserMasterDAO;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import java.util.Date;

import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.json.JSONObject;
import org.springframework.web.client.HttpClientErrorException;

@Controller
public class AuthController {

    // TODO: Set your actual Kakao app info here
    private static final String KAKAO_REST_KEY = "952ba81cd2825efb0931e0e834209b58";
    // If your Kakao app has a client_secret (from Kakao developers settings), set it here; otherwise leave empty
    private static final String KAKAO_CLIENT_SECRET = "Kbsnb9vhoaJl5J2jrbvEwZcS8wTgvFkW";
    // Fallback redirect URI is now configurable via properties (see db.properties)
    @Value("${kakao.redirect.uri.fallback}")
    private String kakaoRedirectUriFallback;

    @Autowired
    private UserMasterDAO userMasterDAO;

    @GetMapping("/login/kakao")
    public RedirectView kakaoLogin(HttpServletRequest request, @RequestParam(name = "returnUrl", required = false) String returnUrl) {
        // Compute redirect URI dynamically from incoming request so the OAuth callback lands on the same host
        String scheme = request.getScheme();
        String host = request.getServerName();
        int port = request.getServerPort();
        String context = request.getContextPath();
        String redirectUri;
        try {
            redirectUri = scheme + "://" + host + (port == 80 || port == 443 ? "" : ":" + port) + context + "/kakao/callback";
        } catch (Exception e) {
            redirectUri = kakaoRedirectUriFallback;
        }

        String url = "https://kauth.kakao.com/oauth/authorize?response_type=code"
                + "&client_id=" + URLEncoder.encode(KAKAO_REST_KEY, StandardCharsets.UTF_8)
                + "&redirect_uri=" + URLEncoder.encode(redirectUri, StandardCharsets.UTF_8);

        // include a state parameter so we can restore returnUrl after callback (optional)
        try {
            if (returnUrl != null && !returnUrl.isEmpty()) {
                String state = URLEncoder.encode(returnUrl, StandardCharsets.UTF_8);
                url += "&state=" + state;
            }
        } catch (Exception e) { /* ignore state encoding errors */ }

        return new RedirectView(url);
    }

    @RequestMapping("/kakao/callback")
    public RedirectView kakaoCallback(@RequestParam(name = "code", required = false) String code,
                                      @RequestParam(name = "state", required = false) String state,
                                      HttpServletRequest request) {
        HttpSession session = request.getSession();

        // Log all incoming request parameters for debugging
        try {
            System.out.println("[KAKAO CALLBACK] Received callback with parameters:");
            request.getParameterMap().forEach((k, v) -> {
                String joined = String.join(",", v);
                System.out.println("[KAKAO CALLBACK] param: " + k + " = " + joined);
            });
        } catch (Exception e) {
            System.out.println("[KAKAO CALLBACK] Failed to log request parameters: " + e.getMessage());
        }

        // Compute redirectUri based on the actual incoming request (must match the one used in authorize)
        String scheme = request.getScheme();
        String host = request.getServerName();
        int port = request.getServerPort();
        String context = request.getContextPath();
        String computedRedirectUri;
        try {
            computedRedirectUri = scheme + "://" + host + (port == 80 || port == 443 ? "" : ":" + port) + context + "/kakao/callback";
        } catch (Exception e) {
            computedRedirectUri = kakaoRedirectUriFallback;
        }

        if (code != null) {
            System.out.println("[KAKAO CALLBACK] authorization code: " + code);

            String accessToken = null;
            JSONObject tokenJson = null;
            JSONObject profileJson = null;

            try {
                // Exchange code for access token
                RestTemplate rest = new RestTemplate();
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

                MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
                body.add("grant_type", "authorization_code");
                body.add("client_id", KAKAO_REST_KEY);
                body.add("redirect_uri", computedRedirectUri);
                body.add("code", code);
                if (KAKAO_CLIENT_SECRET != null && !KAKAO_CLIENT_SECRET.isEmpty()) {
                    body.add("client_secret", KAKAO_CLIENT_SECRET);
                }

                HttpEntity<MultiValueMap<String, String>> tokenRequest = new HttpEntity<>(body, headers);
                ResponseEntity<String> tokenResponse = rest.postForEntity("https://kauth.kakao.com/oauth/token", tokenRequest, String.class);
                String tokenBody = tokenResponse.getBody();
                System.out.println("[KAKAO TOKEN] response: " + tokenBody);

                tokenJson = new JSONObject(tokenBody);
                if (tokenJson.has("access_token")) {
                    accessToken = tokenJson.getString("access_token");
                }
            } catch (HttpClientErrorException hce) {
                System.out.println("[KAKAO TOKEN] token exchange failed: " + hce.getStatusCode() + " : " + hce.getStatusText());
                try {
                    String respBody = hce.getResponseBodyAsString();
                    System.out.println("[KAKAO TOKEN] response body: " + respBody);
                } catch (Exception ex) {
                    System.out.println("[KAKAO TOKEN] no response body available");
                }
                hce.printStackTrace();
                try { session.invalidate(); } catch (Exception ex2) {}
            } catch (Exception e) {
                System.out.println("[KAKAO TOKEN] token exchange failed: " + e.getMessage());
                e.printStackTrace();
                try { session.invalidate(); } catch (Exception ex2) {}
            }

            if (accessToken != null) {
                try {
                    RestTemplate rest = new RestTemplate();
                    HttpHeaders headers = new HttpHeaders();
                    headers.setBearerAuth(accessToken);
                    headers.setAccept(java.util.Collections.singletonList(MediaType.APPLICATION_JSON));

                    HttpEntity<String> profileReq = new HttpEntity<>(headers);
                    ResponseEntity<String> profileResp = rest.exchange("https://kapi.kakao.com/v2/user/me", org.springframework.http.HttpMethod.GET, profileReq, String.class);
                    String profileBody = profileResp.getBody();
                    System.out.println("[KAKAO PROFILE] response: " + profileBody);
                    profileJson = new JSONObject(profileBody);
                } catch (HttpClientErrorException hce) {
                    System.out.println("[KAKAO PROFILE] profile fetch failed: " + hce.getStatusCode() + " : " + hce.getStatusText());
                    try { System.out.println("[KAKAO PROFILE] response body: " + hce.getResponseBodyAsString()); } catch (Exception ex) {}
                    hce.printStackTrace();
                    try { session.invalidate(); } catch (Exception ex2) {}
                } catch (Exception e) {
                    System.out.println("[KAKAO PROFILE] profile fetch failed: " + e.getMessage());
                    e.printStackTrace();
                    try { session.invalidate(); } catch (Exception ex2) {}
                }
            }

            // Build session User and persist to MN_USR_MST
            try {
                String userId = null;
                String email = null;
                String nickname = null;
                String profileImage = null;

                if (profileJson != null) {
                    // Kakao returns id as number
                    if (profileJson.has("id")) {
                        userId = String.valueOf(profileJson.get("id"));
                    }
                    if (profileJson.has("kakao_account")) {
                        JSONObject acc = profileJson.getJSONObject("kakao_account");
                        if (acc.has("email")) email = acc.optString("email", null);
                    }
                    if (profileJson.has("properties")) {
                        JSONObject props = profileJson.getJSONObject("properties");
                        nickname = props.optString("nickname", null);
                        profileImage = props.optString("profile_image", null);
                    }
                }

                // Fallback: use transformed code if profile didn't give id
                if (userId == null) {
                    String numeric = code.replaceAll("\\D", "0");
                    userId = numeric + "1";
                }

                User u = new User();
                try {
                    u.setId(Long.parseLong(userId));
                } catch (Exception e) {
                    u.setId(System.currentTimeMillis());
                }
                u.setNickname(nickname != null ? nickname : "KakaoUser");
                session.setAttribute("USER_SESSION", u);

                UserMaster um = new UserMaster();
                um.setUserId(userId);
                um.setEmail(email);
                um.setNickname(u.getNickname());
                um.setProfileImage(profileImage);
                Date now = new Date();
                um.setLastLogin(now);
                um.setRegDt(now);

                userMasterDAO.insertOrUpdateLogin(um);
                System.out.println("[KAKAO CALLBACK] user persisted/updated: " + userId + ", nickname=" + um.getNickname());

            } catch (Exception ex) {
                System.out.println("[KAKAO CALLBACK] error persisting user: " + ex.getMessage());
                ex.printStackTrace();
                try { session.invalidate(); } catch (Exception ex2) {}
            }
        } else {
            System.out.println("[KAKAO CALLBACK] No authorization code received; parameters were logged above.");
        }

        String ctx = request.getContextPath();
        // If a state (returnUrl) was provided, validate it and redirect there on the same host (state could be absolute or path)
        try {
            if (state != null && !state.isEmpty()) {
                String decoded = java.net.URLDecoder.decode(state, StandardCharsets.UTF_8.name());
                // Allow only path-absolute (starting with '/') or same-origin absolute URLs
                try {
                    if (decoded.startsWith("/")) {
                        return new RedirectView(decoded);
                    }
                    java.net.URL u = new java.net.URL(decoded);
                    String reqOrigin = request.getScheme() + "://" + request.getServerName() + (request.getServerPort() == 80 || request.getServerPort() == 443 ? "" : ":" + request.getServerPort());
                    String urlOrigin = u.getProtocol() + "://" + u.getHost() + (u.getPort() == -1 ? "" : ":" + u.getPort());
                    if (reqOrigin.equalsIgnoreCase(urlOrigin)) {
                        return new RedirectView(decoded);
                    }
                } catch (Exception e) {
                    // not a valid absolute URL - ignore and fall back to index
                }
            }
        } catch (Exception e) {
            // fall back to default
        }

        return new RedirectView(ctx + "/index.jsp");
    }

    @GetMapping("/logout")
    public RedirectView logout(HttpSession session, HttpServletRequest request) {
        session.invalidate();
        String ctx = request.getContextPath();
        return new RedirectView(ctx + "/index.jsp");
    }

    @GetMapping("/auth/check")
    @ResponseBody
    public String checkAuth(HttpSession session) {
        User u = (User) session.getAttribute("USER_SESSION");
        if (u != null) {
            return "OK";
        }
        return "NO";
    }
}
