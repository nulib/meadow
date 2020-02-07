import * as globalVars from "./global-vars";

const cookies = require("cookie");
const nullUser = { token: null };
const loginKey = "loggedIn";

export function anonymous() {
  return !localStorage.getItem(loginKey);
}

export function currentUser() {
  if (anonymous()) {
    return null;
  } else {
    return localStorage.getItem("currentUser");
  }
}

export function login() {
  localStorage.setItem(loginKey, "true");
}

export function logout() {
  localStorage.removeItem(loginKey);
  localStorage.removeItem("currentUser");
  iiifAuth("");
}

export function loginLink() {
  return `${globalVars.ELASTICSEARCH_PROXY_BASE}/auth/login`;
}

async function iiifAuth(token) {
  if (globalVars.IIIF_LOGIN_URL) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", globalVars.IIIF_LOGIN_URL);
    xhr.withCredentials = true;
    xhr.setRequestHeader("Authorization", `Bearer ${token}`);
    await xhr.send();
  }
  return true;
}

export async function extractApiToken(cookieStr) {
  if (anonymous()) {
    return nullUser;
  }

  let ssoToken = cookies.parse(cookieStr).openAMssoToken;
  if (ssoToken != null) {
    try {
      var response = await fetch(
        `${globalVars.ELASTICSEARCH_PROXY_BASE}/auth/callback`,
        { headers: { "X-OpenAM-SSO-Token": ssoToken } }
      );
      var data = await response.json();
      if (data.token != null) {
        await iiifAuth(data.token);
        localStorage.setItem("currentUser", data.user.mail);
        return { token: data.token };
      } else {
        await iiifAuth("");
        localStorage.removeItem(loginKey);
        localStorage.removeItem("currentUser");
        return nullUser;
      }
    } catch (err) {
      console.log("Error: ", err);
      return nullUser;
    }
  } else {
    return nullUser;
  }
}
