package com.ezekielnewren.insidertrading;

import com.ezekielnewren.insidertrading.data.Account;
import com.ezekielnewren.insidertrading.data.User;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;

import javax.servlet.http.HttpSession;
import java.lang.annotation.Annotation;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.*;

/**
 * This class is used by the front end for interfacing with the back.
 */
public class BankAPI {

    SessionManager ctx;

    Map<String, Pair<Method, JsonProperty[]>> call = new HashMap<>();

    public BankAPI(SessionManager _ctx) {
        ctx = _ctx;

        List<Method> methList = Arrays.asList(this.getClass().getMethods());
        for (Method m: methList) {

            if (m.getParameterCount() <= 0) continue;
            if (m.getParameterTypes()[0] != HttpSession.class) continue;

            Annotation[][] annmat = m.getParameterAnnotations();
            JsonProperty[] prop = new JsonProperty[annmat.length-1];
            boolean good = true;
            for (int i=0; i<prop.length; i++) {
                if (annmat[i+1].length != 1 || annmat[i+1][0].getClass() != JsonProperty.class) {
                    good = false;
                    break;
                }
                prop[i] = (JsonProperty) annmat[i+1][0];
            }
            if (!good) continue;

            call.put(m.getName(), new ImmutablePair<>(m, prop));
        }
    }

    String onRequest(HttpSession session, String data) {
        ObjectNode response = ctx.getObjectMapper().createObjectNode();
        JsonNode request;
        try {
            request = ctx.getObjectMapper().readTree(data);
        } catch (JsonProcessingException e) {
            response.put("error", "cannot parse request");
            response.put("data", (String)null);
            return response.toString();
        }

        Pair<Method, JsonProperty[]> tuple = call.get(request.get("cmd").asText());
        Method m = tuple.getLeft();
        JsonProperty[] prop = tuple.getRight();

        Object[] args = new Object[m.getParameterCount()];
        args[0] = session;
        for (int i=0; i<prop.length; i++) {
            args[i+1] = Util.asPOJO(request.get("args").get(prop[i].value()));
        }

        try {
            Object result = m.invoke(this, args);
            response.put("error", (String)null);
            response.putPOJO("data", result);
        } catch (IllegalAccessException|InvocationTargetException e) {
            response.put("error", e.getMessage());
            response.putPOJO("data", null);
        }

        return response.toString();
    }

    public String getUsername(HttpSession session) {
        return ctx.getUsername(session);
    }

    public List<Account> getAccountList(HttpSession session) {
        if (!ctx.isLoggedIn(session)) return null;
        String username = ctx.getUsername(session);

        User user = ctx.getUserStore().getByUsername(username);
        return user.getAccounts();
    }

    public boolean transfer(HttpSession session,
                            @JsonProperty("recipient") String recipient,
                            @JsonProperty("accountTypeFrom") String accountTypeFrom,
                            @JsonProperty("accountTypeTo") String accountTypeTo,
                            @JsonProperty("amount") long amount
    ) {
        // argument checking
        Objects.nonNull(recipient);
        Objects.nonNull(accountTypeFrom);
        Objects.nonNull(accountTypeTo);
        if (amount < 0) throw new IllegalArgumentException();

        String from = getUsername(session);
        if (from == null) return false; // not logged in
        String to = recipient; // do they exist? if not return false

        User userFrom = ctx.getUserStore().getByUsername(from);
        User userTo = ctx.getUserStore().getByUsername(to);

        Account acctFrom = userFrom.getAccount(accountTypeFrom.toString());
        Account acctTo = userTo.getAccount(accountTypeTo.toString());

        // transfer the money only if it makes sense e.g. the from account has at least the amount being transferred
        // your code here ...

        ctx.getUserStore().writeToDatabase(userFrom);
        ctx.getUserStore().writeToDatabase(userTo);

        return true;
    }




}