<!--
Copyright (c) 2018, Yubico AB
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-->
<%@ page import="com.ezekielnewren.Build" %>

<html>
<head>
  <meta charset="utf-8"/>
  <title>WebAuthn Demo</title>
  <link href="css/fonts.css" rel="stylesheet" />
  <link href="css/bootstrap.min.css" rel="stylesheet" media="screen"/>
  <link href="css/bootstrap-responsive.min.css" rel="stylesheet"/>
  <link href="css/bootstrap-yubico.css" rel="stylesheet"/>
  <style type="text/css">

.row {
  display: table-row;
}
.row > * {
  display: table-cell;
  padding: 0.2em;
}

input[type="text"] {
  height: 2em;
  margin: 0;
}

  </style>

  <script src="lib/u2f-api-1.1.js"></script>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
  <script src="lib/text-encoding-0.7.0/encoding.js"></script>
  <script src="lib/text-encoding-0.7.0/encoding-indexes.js"></script>
  <script src="lib/fetch/fetch-3.0.0.js"></script>
  <script src="lib/base64js/base64js-1.3.0.min.js"></script>
  <script src="js/base64url.js"></script>
  <script src="js/webauthn.js"></script>

  <script>

    var urlprefix = <%= Build.get("urlprefix") %>;

    function talk(service, payload) {
      return $.ajax({
        type: 'POST',
        url: urlprefix + service,
        contentType: 'application/json',
        dataType: 'json',
        data: payload,
      })
    }

    //register require key
    function register(username, displayName, nickname, requireResidentKey) {
      var payload = JSON.stringify({username, displayName, nickname, requireResidentKey});

      $.ajax({
        type: 'POST',
        url: urlprefix+'register/start',
        contentType: 'application/json',
        dataType: 'json',
        data: payload,
        success: function(data) {
          var request = data;
          console.log("got the request");
          webauthn.createCredential(request.publicKeyCredentialCreationOptions)
                  .then(function (res) {
                    // Send new credential info to server for verification and registration.
                    var credential = webauthn.responseToObject(res);
                    const body = {
                      requestId: request.requestId,
                      credential,
                    };
                    var json = JSON.stringify(body);
                    // console.log("client signature: "+json);
                    $.ajax({
                      type: 'POST',
                      url: urlprefix + 'register/finish',
                      contentType: 'application/json',
                      dataType: 'json',
                      data: json,
                      success: function(data) {
                        var response = data;
                        document.getElementById('logoutButton').disabled = false;
                        if ("good" == response) {
                          alert("registration successful");
                        }
                      },
                      error: function(errMsg) {
                        document.getElementById('logoutButton').disabled = true;
                        console.log(errMsg);
                      }
                    })
                  }).catch(function (err) {
            // No acceptable authenticator or user refused consent. Handle appropriately.
            console.log(err);
            document.getElementById('logoutButton').disabled = true;
            alert("Failed to add Authenticator");
          });
          // console.log("got a signature");
        },
        error: function(errMsg) {
          console.log(errMsg);
        }
      });

    }

    function login(username, requireResidentKey) {
      var payload = JSON.stringify({username, requireResidentKey});

      talk('login/start', payload)
              .done(function(data) {
                console.log(data);
                // console.log('executeAuthenticateRequest', request);
                var pkcro = data.assertionRequest.publicKeyCredentialRequestOptions;

                return webauthn.getAssertion(pkcro).then(function(assertion) {
                  var requestId = data.requestId;
                  var publicKeyCredential = webauthn.responseToObject(assertion);

                  var payload = JSON.stringify({
                    requestId,
                    publicKeyCredential
                  });

                  talk('login/finish', payload)
                          .done(function(data) {
                            console.log(data);
                            if ("good" === data) {
                              alert("good assertion");
                            }
                          }).catch(function(err) {
                    alert("uh oh, check the log");
                    console.log(err);
                  })
                }).catch(function(err) {
                  console.log(err);
                })
              }).catch(function(err) {
        console.log(err);
      })

    }

    function onRegister() {
      var username = $('#username').val();
      register(username, username, null, false);
    }

    function onLogin() {
      var username = $('#username').val();
      login(username, false);
    }

    function onLogout() {
      //possibly clear session and cookies?
      document.getElementById('logoutButton').disabled = true;
    }

<%--let ceremonyState = {};--%>
<%--let session = {--%>
<%--};--%>

<%--function extend(obj, more) {--%>
<%--  return Object.assign({}, obj, more);--%>
<%--}--%>

<%--function rejectIfNotSuccess(response) {--%>
<%--  if (response.success) {--%>
<%--    return response;--%>
<%--  } else {--%>
<%--    return new Promise((resolve, reject) => reject(response));--%>
<%--  }--%>
<%--}--%>

<%--function updateSession(response) {--%>
<%--  if (response.sessionToken) {--%>
<%--     session.sessionToken = response.sessionToken;--%>
<%--  }--%>
<%--  if (response.username) {--%>
<%--    session.username = response.username;--%>
<%--  }--%>
<%--  updateSessionBox();--%>
<%--  updateRegisterButtons();--%>
<%--  return response;--%>
<%--}--%>

// function logout() {
//   session = {};
//   updateSession({});
// }

<%--function updateSessionBox() {--%>
<%--  if (session.username) {--%>
<%--    document.getElementById('session').textContent = `Logged in as ${session.username}`;--%>
<%--    document.getElementById('logoutButton').disabled = false;--%>
<%--  } else {--%>
<%--    document.getElementById('session').textContent = 'Not logged in.';--%>
<%--    document.getElementById('logoutButton').disabled = true;--%>
<%--  }--%>
<%--}--%>

<%--function updateRegisterButtons() {--%>
<%--  if (session.sessionToken) {--%>
<%--     document.getElementById('registerButton').textContent = 'Add credential';--%>
<%--     document.getElementById('registerRkButton').textContent = 'Add resident credential';--%>
<%--  } else {--%>
<%--     document.getElementById('registerButton').textContent = 'Register new account';--%>
<%--     document.getElementById('registerRkButton').textContent = 'Register new account with resident credential';--%>
<%--  }--%>
<%--}--%>

<%--function rejected(err) {--%>
<%--  return new Promise((resolve, reject) => reject(err));--%>
<%--}--%>

<%--function setStatus(statusText) {--%>
<%--  document.getElementById('status').textContent = statusText;--%>
<%--}--%>

<%--function addMessage(message) {--%>
<%--  const el = document.getElementById('messages');--%>
<%--  const p = document.createElement('p');--%>
<%--  p.appendChild(document.createTextNode(message));--%>
<%--  el.appendChild(p);--%>
<%--}--%>

<%--function addMessages(messages) {--%>
<%--  messages.forEach(addMessage);--%>
<%--}--%>

<%--function clearMessages() {--%>
<%--  const el = document.getElementById('messages');--%>
<%--  while (el.firstChild) {--%>
<%--    el.removeChild(el.firstChild);--%>
<%--  }--%>
<%--}--%>

<%--function showJson(name, data) {--%>
<%--  const el = document.getElementById(name)--%>
<%--    .textContent = JSON.stringify(data, false, 2);--%>
<%--}--%>
<%--function showRequest(data) { return showJson('request', data); }--%>
<%--function showAuthenticatorResponse(data) {--%>
<%--  const clientDataJson = data && (data.response && data.response.clientDataJSON || data.u2fResponse.clientDataJSON);--%>
<%--  return showJson('authenticator-response', extend(--%>
<%--    data, {--%>
<%--    _clientDataJson: data && JSON.parse(new TextDecoder('utf-8').decode(base64url.toByteArray(clientDataJson))),--%>
<%--  }));--%>
<%--}--%>
<%--function showServerResponse(data) {--%>
<%--  if (data && data.messages) {--%>
<%--    addMessages(data.messages);--%>
<%--  }--%>
<%--  return showJson('server-response', data);--%>
<%--}--%>

<%--function hideDeviceInfo() {--%>
<%--  document.getElementById("device-info").style = "display: none";--%>
<%--}--%>
<%--function showDeviceInfo(params) {--%>
<%--  document.getElementById("device-info").style = undefined;--%>
<%--  document.getElementById("device-name").textContent = params.displayName;--%>
<%--  document.getElementById("device-nickname").textContent = params.nickname;--%>
<%--  document.getElementById("device-icon").src = params.imageUrl;--%>
<%--}--%>

<%--function resetDisplays() {--%>
<%--  clearMessages();--%>
<%--  showRequest(null);--%>
<%--  showAuthenticatorResponse(null);--%>
<%--  showServerResponse(null);--%>
<%--  hideDeviceInfo();--%>
<%--}--%>

<%--function getIndexActions() {--%>
<%--  return fetch('api/v1/')--%>
<%--    .then(response => response.json())--%>
<%--    .then(data => data.actions)--%>
<%--  ;--%>
<%--}--%>

<%--function getRegisterRequest(urls, username, displayName, credentialNickname, requireResidentKey = false) {--%>
<%--  return fetch(urls.register, {--%>
<%--    body: new URLSearchParams({--%>
<%--      username,--%>
<%--      displayName,--%>
<%--      credentialNickname,--%>
<%--      requireResidentKey,--%>
<%--      sessionToken: session.sessionToken || null,--%>
<%--    }),--%>
<%--    method: 'POST',--%>
<%--  })--%>
<%--    .then(response => response.json())--%>
<%--    .then(updateSession)--%>
<%--    .then(rejectIfNotSuccess)--%>
<%--  ;--%>
<%--}--%>

<%--function executeRegisterRequest(request, useU2f = false) {--%>
<%--  console.log('executeRegisterRequest', request);--%>

<%--  if (useU2f) {--%>
<%--    return executeU2fRegisterRequest(request);--%>
<%--  } else {--%>
<%--    return webauthn.createCredential(request.publicKeyCredentialCreationOptions);--%>
<%--  }--%>
<%--}--%>

<%--function executeU2fRegisterRequest(request) {--%>
<%--  const appId = 'https://www.ezekielnewren.com';--%>
<%--  console.log('appId', appId);--%>
<%--  return u2fRegister(--%>
<%--    appId,--%>
<%--    [{--%>
<%--      version: 'U2F_V2',--%>
<%--      challenge: request.publicKeyCredentialCreationOptions.challenge,--%>
<%--      attestation: 'direct',--%>
<%--    }],--%>
<%--    request.publicKeyCredentialCreationOptions.excludeCredentials.map(cred => ({--%>
<%--      version: 'U2F_V2',--%>
<%--      keyHandle: cred.id,--%>
<%--    }))--%>
<%--  )--%>
<%--    .then(result => {--%>
<%--      const registrationDataBase64 = result.registrationData;--%>
<%--      const clientDataBase64 = result.clientData;--%>
<%--      const registrationDataBytes = base64url.toByteArray(registrationDataBase64);--%>

<%--      const publicKeyBytes = registrationDataBytes.slice(1, 1 + 65);--%>
<%--      const L = registrationDataBytes[1 + 65];--%>
<%--      const keyHandleBytes = registrationDataBytes.slice(1 + 65 + 1, 1 + 65 + 1 + L);--%>

<%--      const attestationCertAndTrailingBytes = registrationDataBytes.slice(1 + 65 + 1 + L);--%>

<%--      return {--%>
<%--        u2fResponse: {--%>
<%--          keyHandle: base64url.fromByteArray(keyHandleBytes),--%>
<%--          publicKey: base64url.fromByteArray(publicKeyBytes),--%>
<%--          attestationCertAndSignature: base64url.fromByteArray(attestationCertAndTrailingBytes),--%>
<%--          clientDataJSON: clientDataBase64,--%>
<%--        },--%>
<%--      };--%>
<%--    })--%>
<%--  ;--%>
<%--}--%>

<%--function u2fRegister(appId, registerRequests, registeredKeys) {--%>
<%--  return new Promise((resolve, reject) => {--%>
<%--    u2f.register(--%>
<%--      appId,--%>
<%--      registerRequests,--%>
<%--      registeredKeys,--%>
<%--      data => {--%>
<%--        if (data.errorCode) {--%>
<%--          switch (data.errorCode) {--%>
<%--            case 2:--%>
<%--              reject(new Error('Bad request.'));--%>
<%--              break;--%>

<%--            case 4:--%>
<%--              reject(new Error('This device is already registered.'));--%>
<%--              break;--%>

<%--            default:--%>
<%--              reject(new Error(`U2F failed with error: ${data.errorCode}`));--%>
<%--          }--%>
<%--        } else {--%>
<%--          resolve(data);--%>
<%--        }--%>
<%--      }--%>
<%--    );--%>
<%--  });--%>
<%--}--%>

<%--function submitResponse(url, request, response) {--%>
<%--  console.log('submitResponse', url, request, response);--%>

<%--  const body = {--%>
<%--    requestId: request.requestId,--%>
<%--    credential: response,--%>
<%--    sessionToken: request.sessionToken || session.sessionToken || null,--%>
<%--  };--%>

<%--  return fetch(url, {--%>
<%--    method: 'POST',--%>
<%--    body: JSON.stringify(body),--%>
<%--  })--%>
<%--    .then(response => response.json())--%>
<%--    .then(updateSession)--%>
<%--  ;--%>
<%--}--%>

<%--function performCeremony(params) {--%>
<%--  const callbacks = params.callbacks || {}; /* { init, authenticatorRequest, serverRequest } */--%>
<%--  const getIndexActions = params.getIndexActions; /* function(): object */--%>
<%--  const getRequest = params.getRequest; /* function(urls: object): { publicKeyCredentialCreationOptions: object } | { publicKeyCredentialRequestOptions: object } */--%>
<%--  const statusStrings = params.statusStrings; /* { init, authenticatorRequest, serverRequest, success, } */--%>
<%--  const executeRequest = params.executeRequest; /* function({ publicKeyCredentialCreationOptions: object } | { publicKeyCredentialRequestOptions: object }): Promise[PublicKeyCredential] */--%>
<%--  const handleError = params.handleError; /* function(err): ? */--%>
<%--  const useU2f = params.useU2f; /* boolean */--%>

<%--  setStatus('Looking up API paths...');--%>
<%--  resetDisplays();--%>

<%--  return getIndexActions()--%>
<%--    .then(urls => {--%>
<%--      setStatus(statusStrings.int);--%>
<%--      if (callbacks.init) {--%>
<%--        callbacks.init(urls);--%>
<%--      }--%>
<%--      return getRequest(urls);--%>
<%--    })--%>

<%--    .then((params) => {--%>
<%--      const request = params.request;--%>
<%--      const urls = params.actions;--%>
<%--      setStatus(statusStrings.authenticatorRequest);--%>
<%--      if (callbacks.authenticatorRequest) {--%>
<%--        callbacks.authenticatorRequest({ request, urls });--%>
<%--      }--%>
<%--      showRequest(request);--%>
<%--      ceremonyState = {--%>
<%--        callbacks,--%>
<%--        request,--%>
<%--        statusStrings,--%>
<%--        urls,--%>
<%--        useU2f,--%>
<%--      };--%>
<%--      return executeRequest(request)--%>
<%--        .then(webauthn.responseToObject);--%>
<%--    })--%>
<%--    .then(finishCeremony)--%>
<%--  ;--%>
<%--}--%>

<%--function finishCeremony(response) {--%>
<%--  const callbacks = ceremonyState.callbacks;--%>
<%--  const request = ceremonyState.request;--%>
<%--  const statusStrings = ceremonyState.statusStrings;--%>
<%--  const urls = ceremonyState.urls;--%>
<%--  const useU2f = ceremonyState.useU2f;--%>

<%--  setStatus(statusStrings.serverRequest || 'Sending response to server...');--%>
<%--  if (callbacks.serverRequest) {--%>
<%--    callbacks.serverRequest({ urls, request, response });--%>
<%--  }--%>
<%--  showAuthenticatorResponse(response);--%>

<%--  return submitResponse(useU2f ? urls.finishU2f : urls.finish, request, response)--%>
<%--    .then(data => {--%>
<%--      if (data && data.success) {--%>
<%--        setStatus(statusStrings.success);--%>
<%--      } else {--%>
<%--        setStatus('Error!');--%>
<%--      }--%>
<%--      showServerResponse(data);--%>
<%--      return data;--%>
<%--    });--%>
<%--}--%>

<%--function registerResidentKey() {--%>
<%--  return register(requireResidentKey = true);--%>
<%--}--%>

<%--function register(requireResidentKey = false, getRequest = getRegisterRequest) {--%>
<%--  const username = document.getElementById('username').value;--%>
<%--  const displayName = document.getElementById('displayName').value;--%>
<%--  const credentialNickname = document.getElementById('credentialNickname').value;--%>
<%--  const useU2f = document.getElementById('useU2f').checked;--%>

<%--  var request;--%>

<%--  return performCeremony({--%>
<%--    getIndexActions,--%>
<%--    getRequest: urls => getRequest(urls, username, displayName, credentialNickname, requireResidentKey),--%>
<%--    statusStrings: {--%>
<%--      init: 'Initiating registration ceremony with server...',--%>
<%--      authenticatorRequest: 'Asking authenticators to create credential...',--%>
<%--      success: 'Registration successful!',--%>
<%--    },--%>
<%--    executeRequest: req => {--%>
<%--      request = req;--%>
<%--      return executeRegisterRequest(req, useU2f);--%>
<%--    },--%>
<%--    useU2f,--%>
<%--  })--%>
<%--  .then(data => {--%>
<%--    if (data.registration) {--%>
<%--      const nicknameInfo = {--%>
<%--        nickname: data.registration.credentialNickname,--%>
<%--      };--%>

<%--      if (data.registration && data.registration.attestationMetadata) {--%>
<%--        showDeviceInfo(extend(--%>
<%--          data.registration.attestationMetadata.deviceProperties,--%>
<%--          nicknameInfo--%>
<%--        ));--%>
<%--      } else {--%>
<%--        showDeviceInfo(nicknameInfo);--%>
<%--      }--%>

<%--      if (!data.attestationTrusted) {--%>
<%--        addMessage("Warning: Attestation is not trusted!");--%>
<%--      }--%>
<%--    }--%>
<%--  })--%>
<%--  .catch((err) => {--%>
<%--    setStatus('Registration failed.');--%>
<%--    console.error('Registration failed', err);--%>

<%--    if (err.name === 'NotAllowedError') {--%>
<%--      if (request.publicKeyCredentialCreationOptions.excludeCredentials--%>
<%--          && request.publicKeyCredentialCreationOptions.excludeCredentials.length > 0--%>
<%--      ) {--%>
<%--        addMessage('Credential creation failed, probably because an already registered credential is avaiable.');--%>
<%--      } else {--%>
<%--        addMessage('Credential creation failed for an unknown reason.');--%>
<%--      }--%>
<%--    } else if (err.name === 'InvalidStateError') {--%>
<%--      addMessage(`This authenticator is already registered for the account "${username}". Please try again with a different authenticator.`)--%>
<%--    } else if (err.message) {--%>
<%--      addMessage(`${err.name}: ${err.message}`);--%>
<%--    } else if (err.messages) {--%>
<%--      addMessages(err.messages);--%>
<%--    }--%>
<%--    return rejected(err);--%>
<%--  });--%>
<%--}--%>

<%--function getAuthenticateRequest(urls, username) {--%>
<%--  return fetch(urls.authenticate, {--%>
<%--    body: new URLSearchParams(username ? { username } : {}),--%>
<%--    method: 'POST',--%>
<%--  })--%>
<%--    .then(response => response.json())--%>
<%--    .then(updateSession)--%>
<%--    .then(rejectIfNotSuccess)--%>
<%--  ;--%>
<%--}--%>

<%--function executeAuthenticateRequest(request) {--%>
<%--  console.log('executeAuthenticateRequest', request);--%>

<%--  return webauthn.getAssertion(request.publicKeyCredentialRequestOptions);--%>
<%--}--%>

<%--function authenticateWithUsername() {--%>
<%--  return authenticate(username = document.getElementById('username').value);--%>
<%--}--%>
<%--function authenticate(username = null, getRequest = getAuthenticateRequest) {--%>
<%--  return performCeremony({--%>
<%--    getIndexActions,--%>
<%--    getRequest: urls => getRequest(urls, username),--%>
<%--    statusStrings: {--%>
<%--      init: 'Initiating authentication ceremony with server...',--%>
<%--      authenticatorRequest: 'Asking authenticators to perform assertion...',--%>
<%--      success: 'Authentication successful!',--%>
<%--    },--%>
<%--    executeRequest: executeAuthenticateRequest,--%>
<%--  }).then(data => {--%>
<%--    if (data.registrations) {--%>
<%--      addMessage(`Authenticated as: ${data.registrations[0].username}`);--%>
<%--    }--%>
<%--    return data;--%>
<%--  }).catch((err) => {--%>
<%--    setStatus('Authentication failed.');--%>
<%--    if (err.name === 'InvalidStateError') {--%>
<%--      addMessage(`This authenticator is not registered for the account "${username}". Please try again with a registered authenticator.`)--%>
<%--    } else if (err.message) {--%>
<%--      addMessage(`${err.name}: ${err.message}`);--%>
<%--    } else if (err.messages) {--%>
<%--      addMessages(err.messages);--%>
<%--    }--%>
<%--    console.error('Authentication failed', err);--%>
<%--    return rejected(err);--%>
<%--  });--%>
<%--}--%>

<%--function deregister() {--%>
<%--  const credentialId = document.getElementById('deregisterCredentialId').value;--%>
<%--  addMessage('Deregistering credential...');--%>

<%--  return getIndexActions()--%>
<%--    .then(urls =>--%>
<%--      fetch(urls.deregister, {--%>
<%--       body: new URLSearchParams({--%>
<%--         credentialId,--%>
<%--         sessionToken: session.sessionToken || null,--%>
<%--       }),--%>
<%--       method: 'POST',--%>
<%--     })--%>
<%--    )--%>
<%--    .then(response => response.json())--%>
<%--    .then(updateSession)--%>
<%--    .then(rejectIfNotSuccess)--%>
<%--    .then(data => {--%>
<%--      if (data.success) {--%>
<%--        if (data.droppedRegistration) {--%>
<%--          addMessage(`Successfully deregistered credential: ${data.droppedRegistration.credentialNickname || credentialId}`);--%>
<%--        } else {--%>
<%--          addMessage(`Successfully deregistered credential: ${credentialId}`);--%>
<%--        }--%>
<%--        if (data.accountDeleted) {--%>
<%--          addMessage('No credentials remain - account deleted.');--%>
<%--          logout();--%>
<%--        }--%>
<%--      } else {--%>
<%--        addMessage('Credential deregistration failed.');--%>
<%--      }--%>
<%--    })--%>
<%--    .catch((err) => {--%>
<%--      setStatus('Credential deregistration failed.');--%>
<%--      if (err.message) {--%>
<%--        addMessage(`${err.name}: ${err.message}`);--%>
<%--      } else if (err.messages) {--%>
<%--        addMessages(err.messages);--%>
<%--      }--%>
<%--      console.error('Authentication failed', err);--%>
<%--      return rejected(err);--%>
<%--    });--%>
<%--}--%>

function init() {
  hideDeviceInfo();
  return false;
}

window.onload = init;

</script>

</head>
<body>

<div class="base">
  <div class="content">

    <div class="header-logo visible-desktop">
      <a href="https://www.yubico.com/" title="Yubico">
        <img src="img/yubico-logo.png"/>
      </a>
    </div>

    <h1> Test your WebAuthn device </h1>

    <form class="horizontal">
      <div class="row">
        <label for="username">Username:</label>
        <div><input type="text" id="username"/></div>
      </div>
      <div class="row">
        <label for="displayName">Display name:</label>
        <div><input type="text" id="displayName"/></div>
      </div>

      <div class="row">
        <label for="credentialNickname">Credential nickname:</label>
        <div><input type="text" id="credentialNickname"/></div>
        <div>
          <!--currently set to require username, nickname, display name and key-->
<%--          <button type="button" id="registerButton" onClick="javascript:register()">--%>
<%--            Register new account--%>
<%--          </button>--%>
              <button type="button" id="registerButton" onClick="onRegister()">
                Register new account
              </button>
        </div>
        <!--currently set to require username, nickname, display name and key-->
        <div>
<%--          <button type="button" id="registerRkButton" onClick="javascript:registerResidentKey()">--%>
<%--            Register new account with resident credential--%>
<%--          </button>--%>
              <button type="button" id="registerRkButton" onClick="onRegister()">
                Register new account with resident credential
              </button>
        </div>
      </div>

      <div class="row">
        <div></div>
        <div></div>
        <div>
          <button type="button" onClick="javascript:authenticateWithUsername()">
            Authenticate
          </button>
        </div>
        <div>
          <button type="button" onClick="javascript:authenticate()">
            Authenticate without username
          </button>
        </div>
      </div>

      <div class="row">
        <div></div>
        <div></div>
        <div>
          <input type="checkbox" id="useU2f"/>
          <label for="useU2f">Use U2F API to register</label>
        </div>
      </div>

      <div class="row">
        <label for="deregisterCredentialId">Credential ID:</label>
        <div><input type="text" id="deregisterCredentialId"/></div>
        <div>
          <button type="button" onClick="javascript:deregister()">
            Deregister
          </button>
        </div>
      </div>
    </form>


<%--    <p id="session">Not logged in.</p>--%>
<%--    <button id="logoutButton" disabled="disabled" onClick="javascript:logout()">Log out</button>--%>
<%--    <p id="status"></p>--%>

    <p id="session">Not logged in.</p>
    <button id="logoutButton" disabled="disabled" onClick="onLogout()">Log out</button>
    <p id="status"></p>
    <div id="messages"></div>

    <div id="device-info">
      <img id="device-icon"/>
      <b>Device: </b><span id="device-name"></span>
      <b>Nickname: </b><span id="device-nickname"></span>
    </div>

    Server response: <pre id="server-response"></pre>
    Authenticator response: <pre id="authenticator-response"></pre>
    Request: <pre id="request"></pre>

  </div>
</div>

</body>
</html>