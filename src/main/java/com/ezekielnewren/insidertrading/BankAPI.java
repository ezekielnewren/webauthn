package com.ezekielnewren.insidertrading;

import com.ezekielnewren.insidertrading.data.Account;
import com.ezekielnewren.insidertrading.data.Transaction;
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
import com.mongodb.client.FindIterable;
import com.mongodb.client.model.Filters;

import javax.servlet.http.HttpSession;
import java.util.*;

/**
 * This class is used by the front end for interfacing with the back.
 */
public class BankAPI {

    /**
     * {@code SessionManager} object.
     * @see com.ezekielnewren.insidertrading.SessionManager
     */
    SessionManager ctx;

    Map<String, Pair<Method, JsonProperty[]>> call = new HashMap<>();

    /**
     * Constructor for {@code BankAPI}.
     * @param _ctx context for {@code SessionManager}.
     * @see com.ezekielnewren.insidertrading.SessionManager
     */
    public BankAPI(SessionManager _ctx) {
        ctx = _ctx;
    }

    /**
     *
     * @param session
     * @param data
     * @return
     * @throws JsonProcessingException
     * @see javax.servlet.http.HttpSession
     * @see java.lang.String
     */
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

    /**
     * Get username from the {@code session}.
     * @param session current {@code session}.
     * @return the username from the {@code session}.
     * @see javax.servlet.http.HttpSession
     */
    public String getUsername(HttpSession session) {
        return ctx.getUsername(session);
    }

    /**
     * Checks if user is logged in, if they are gets account information for user.
     * @param session current {@code session}.
     * @return if not logged in null else account for the user.
     * @see javax.servlet.http.HttpSession
     */
    public List<Account> getAccountList(HttpSession session) {
        if (!ctx.isLoggedIn(session)) return null;
        String username = ctx.getUsername(session);

        User user = ctx.getUserStore().getByUsername(username);
        return user.getAccounts();
    }

    /**
     *
     * @param session
     * @param recipient
     * @param accountTypeFrom
     * @param accountTypeTo
     * @param amount
     * @return true if it is allowed to go through
     * @see javax.servlet.http.HttpSession
     * @see java.lang.String
     */
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
        if(userTo == null) return false;

        Account acctFrom = userFrom.getAccount(accountTypeFrom.toString());
        Account acctTo = userTo.getAccount(accountTypeTo.toString());

        // transfer the money only if it makes sense e.g. the from account has at least the amount being transferred
        // your code here ...
        if(acctFrom.balance < amount){
            return false;
            //maybe return exception instead.
        }
        acctFrom.balance = acctFrom.balance - amount;
        acctTo.balance = acctTo.balance + amount;

        ctx.getUserStore().writeToDatabase(userFrom);
        ctx.getUserStore().writeToDatabase(userTo);
        Transaction t = new Transaction(acctFrom.getNumber(), acctTo.getNumber(), amount, System.currentTimeMillis());
        ctx.collectionTransaction.insertOne(t);
        return true;
    }

    /**
     * @return
     * @see java.util.List
     */
    public String getTransactionHistory(HttpSession session) {

        String userN = getUsername(session);
        User u = ctx.getUserStore().getByUsername(userN);
        List<Account> aList = u.getAccounts();

        List<Transaction> tList = new ArrayList<>();

        for(Account a : aList){
            tList.add((Transaction)ctx.collectionTransaction.find(Filters.eq("sendingAccount", a.getNumber())));
            tList.add((Transaction)ctx.collectionTransaction.find(Filters.eq("receivingAccount", a.getNumber())));
        }

        try {
            return ctx.getObjectMapper().writeValueAsString(tList);
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return null;
        }
    }

    public void logout(HttpSession session){

        ctx.clearLoggedIn(session);
        
    }




}
