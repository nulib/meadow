const isString = require("lodash.isstring");
const fetch = require("node-fetch");
const { dcApiEndpoint, allowedFrom } = require("./environment.json");

const allowedFromRegexes = ((str) => {
  const configValues = isString(str) ? str.split(";") : [];
  const result = [];
  for (const re in configValues) {
    result.push(new RegExp(configValues[re]));
  }
  return result;
})(allowedFrom);

async function authorize(id, referer, cookie) {
  for (const re of allowedFromRegexes) {
    if (re.test(referer)) {
      console.log(`Stream authorized: Referred by ${referer}`);
      return true;
    }
  }

  return await getImageAuthorization(id, cookie);
}

async function getImageAuthorization(id, cookieHeader) {
  const opts = {
    headers: {
      cookie: cookieHeader,
    },
  };

  const response = await fetch(
    `${dcApiEndpoint}/file-sets/${id}/authorization`,
    opts
  );
  if (response.status == 204) {
    console.log(`Access to ${id} authorized via API request`);
    return true;
  }

  console.log(`Access to ${id} denied: API response status ${response.status}`);
  return false;
}

module.exports = authorize;
