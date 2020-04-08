package com.ezekielnewren.insidertrading.data;

import com.ezekielnewren.insidertrading.Util;
import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.yubico.webauthn.RegisteredCredential;
import com.yubico.webauthn.data.ByteArray;
import lombok.Getter;
import lombok.NonNull;
import org.bson.types.ObjectId;

import java.util.*;

/**
 * The class {@code User} contains user information, constructs user {@code JSON} and constructs users.
 *
 * <p>
 *     {@code JSON} formatting is used for {@code Jackson}. Will need to implement {@link com.ezekielnewren.insidertrading.JacksonHelper}
 *     to convert {@code JSON} so {@code Mongo} can interpret it.
 * </p>
 */
@JsonAutoDetect(getterVisibility = JsonAutoDetect.Visibility.NONE,
        isGetterVisibility = JsonAutoDetect.Visibility.NONE,
        setterVisibility = JsonAutoDetect.Visibility.NONE,
        creatorVisibility = JsonAutoDetect.Visibility.NONE,
        fieldVisibility = JsonAutoDetect.Visibility.PUBLIC_ONLY
)
@Getter
public class User {

    /**
     * 12-byte primary key value for user.
     */
    @JsonProperty @NonNull final ObjectId _id;

    /**
     * Username for user.
     */
    @JsonProperty @NonNull String username;

    /**
     * Display name for user.
     */
    @JsonProperty @NonNull Optional<String> displayName;

    /**
     * List of emails for user.
     */
    @JsonProperty @NonNull List<String> email;

    /**
     * List of authenticators for user.
     */
    @JsonProperty @NonNull List<Authenticator> authenticator;

    /**
     * First name for user.
     */
    @JsonProperty @NonNull String firstName;

    /**
     * Last name for user.
     */
    @JsonProperty @NonNull String lastName;

    /**
     * SSN for user.
     */
    @JsonProperty int ssn;

    /**
     * Account for user.
     */
    @JsonProperty @NonNull Map<String, Account> account;


    /**
     * <p>Constructs a {@code User JSON} object. If a null is passed for a list type it will.
     * be changed to an empty list.</p>
     * @param _id generated user id.
     * @param _username user specified name.
     * @param _displayName user specified name (optional).
     * @param _email list user specified email(s).
     * @param _authenticator list user give authenticator(s).
     * @param _firstName user specified firstname.
     * @param _lastName user specified lastname.
     * @param _ssn user specified ssn.
     * @param _account used for Account.
     * @see org.bson.types.ObjectId
     * @see java.lang.String
     * @see java.util.List
     */
    @JsonCreator
    public User(@JsonProperty("_id") final ObjectId _id,
                @JsonProperty("username") String _username,
                @JsonProperty("displayName") String _displayName,
                @JsonProperty("email") List<String> _email,
                @JsonProperty("authenticator") List<Authenticator> _authenticator,
                @JsonProperty("firstName") String _firstName,
                @JsonProperty("lastName") String _lastName,
                @JsonProperty("ssn") int _ssn,
                @JsonProperty("account") List<Account> _account

    ) {
        this._id = _id;
        this.username = _username;
        this.displayName = Optional.ofNullable(_displayName);
        this.email = Optional.ofNullable(_email).orElseGet(()->new ArrayList<>());
        this.authenticator = Optional.ofNullable(_authenticator).orElseGet(()->new ArrayList<>());
        this.firstName = _firstName;
        this.lastName = _lastName;
        this.ssn = _ssn;
        List<Account> tmp = Optional.ofNullable(_account).orElseGet(()->new ArrayList<>());
        this.account = new LinkedHashMap<>();
        for (Account item: tmp) {
            account.put(item.title, item);
        }
    }

    /**
     * Creates a new {@code List} and adds the two default account types.
     * @return the new {@code List}.
     */
    static List<Account> createEmptyAccountList() {
        List<Account> list = new ArrayList<>();

        list.add(new Account(Account.DefaultNames.Savings.toString(), 0));
        list.add(new Account(Account.DefaultNames.Checking.toString(), 0));

        return list;
    }

    /**
     * Constructs a {@code User} object.
     * @param _username user provided name.
     * @param _displayName optional parameter, username if user did not specify.
     */
    public User(String _username, String _displayName) {
        this(new ObjectId(), _username, _displayName, null, null, null, null, 0, createEmptyAccountList());
    }

    /**
     * Gets userhandle.
     * @return new byte array with id byte array.
     * @see com.yubico.webauthn.data.ByteArray
     */
    public ByteArray getUserHandle() {
        return new ByteArray(_id.toByteArray());
    }


    /**
     * Gets the display name.
     * @return a the display name or, if none given, username.
     */
    public String getDisplayName() {
        return displayName.orElse(username);
    }

    /**
     * Gets the registered credentials using id.
     * @param credentialId id generated by authenticator.
     * @return null if auth is null or registered credentials.
     * @see com.yubico.webauthn.data.ByteArray
     */
    public RegisteredCredential getRegisteredCredential(ByteArray credentialId) {
        Authenticator auth = getAuthenticator(credentialId);

        return Util.getRegisteredCredential(auth, getUserHandle());
    }

    /**
     * Gets authenticator using id.
     * @param credentialId id generated by authenticator.
     * @return authenticator or null.
     * @see com.yubico.webauthn.data.ByteArray
     */
    public Authenticator getAuthenticator(@NonNull ByteArray credentialId) {
        for (Authenticator auth: getAuthenticator()) {
            if (credentialId.equals(auth.getCredentialId())) return auth;
        }
        return null;
    }

    /**
     * Gets list of account.
     * @return an arraylist of account.
     * @see java.util.ArrayList
     */
    @JsonProperty("account")
    public List<Account> getAccount() {
        return new ArrayList<>(account.values());
    }

    /**
     * Get account by type (checking, savings, etc.).
     * @param _title account type.
     * @return account type.
     * @see java.lang.String
     */
    public Account getAccount(String _title) {
        return account.get(_title);
    }

    /**
     * Creates an account.
     * @param _title name.
     * @throws RuntimeException detailed exception if the account type exists in that account.
     * @see java.lang.String
     */
    public void createAccount(String _title) {
        if (account.containsKey(_title)) throw new RuntimeException("account: "+_title+" already exists");
        account.put(_title, new Account(_title, 0));
    }

    /**
     * Sets the {@code username}.
     * @param _username username.
     */
    public void setUsername(String _username) {
        this.username = _username;
    }
}
