package com.mn.cm.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import com.mn.cm.dao.GenreDAO;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
public class GenreLookupController {

    @Autowired
    private GenreDAO genreDAO;

    // Accepts JSON body: { ids: [1,2,3] }
    @PostMapping(value = "/genre/names", produces = "application/json; charset=UTF-8")
    @ResponseBody
    public Map<String,Object> lookupNames(@RequestBody Map<String,Object> payload) {
        Map<String,Object> out = new HashMap<>();
        try {
            List<Integer> ids = null;
            if (payload != null && payload.get("ids") instanceof List) {
                ids = (List<Integer>) payload.get("ids");
            }
            java.util.List<java.util.Map<String,Object>> rows = genreDAO.selectNamesByIds(ids);
            Map<String,String> map = new HashMap<>();
            if (rows != null) {
                for (Map<String,Object> r : rows) {
                    try {
                        Object id = r.get("genreId");
                        Object nm = r.get("genreNm");
                        if (id != null && nm != null) map.put(String.valueOf(id), String.valueOf(nm));
                    } catch (Exception ignore) {}
                }
            }
            out.put("status", "OK");
            out.put("data", map);
            return out;
        } catch (Exception e) {
            out.put("status", "ERR");
            out.put("message", e.getMessage());
            return out;
        }
    }
}
