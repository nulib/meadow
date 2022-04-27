const isObject = require("lodash.isobject");
const isString = require("lodash.isstring");
const AWS = require("aws-sdk");
const elasticSearch = process?.env?.ELASTICSEARCH_URL || "${elastic_search}";

async function authorize(id) {
  const doc = await getDoc(id);
  const visibility = getVisibility(doc._source);
  console.log(`Visibility for $${id}: $${visibility}`);
  return visibility == "open" ? true : false;
}

async function getDoc(id) {
  const docUrl = new URL(["meadow", "_doc", id].join("/"), elasticSearch).href;
  const request = await makeRequest("GET", docUrl);
  const response = await fetchJson(request);
  return response.json;
}

function getVisibility(source) {
  if (!isObject(source)) return null;

  if (isObject(source.visibility)) {
    return source.visibility.id.toLowerCase();
  } else if (isString(source.visibility)) {
    return source.visibility.toLowerCase();
  }

  return null;
}

function fetchJson(request) {
  return new Promise((resolve, _reject) => {
    var client = new AWS.HttpClient();
    client.handleRequest(
      request,
      null,
      (response) => {
        var responseBody = "";
        response.on("data", (chunk) => {
          responseBody += chunk;
        });
        response.on("end", () => {
          response.body = responseBody;
          response.json = JSON.parse(responseBody);
          resolve(response);
        });
      },
      (error) => {
        console.log("ERROR RETRIEVING AUTH DOCUMENT: ", error);
        resolve(null);
      }
    );
  });
}

function makeRequest(method, requestUrl, body = null) {
  return new Promise((resolve, reject) => {
    const region =
      process?.env?.ELASTICSEARCH_REGION ||
      elasticSearch
        .match(/\.([a-z]{2}-[a-z]+-\d)\./)
        .slice(-1)
        .toString();
    const chain = new AWS.CredentialProviderChain();
    const request = new AWS.HttpRequest(requestUrl, region);
    request.method = method;
    request.headers["Host"] = new URL(requestUrl).hostname;
    request.body = body;
    request.headers["Content-Type"] = "application/json";

    chain.resolve((err, credentials) => {
      if (err) {
        console.log("WARNING: ", err);
        console.log("Returning unsigned request");
      } else {
        var signer = new AWS.Signers.V4(request, "es");
        signer.addAuthorization(credentials, new Date());
      }
      resolve(request);
    });
  });
}

module.exports = authorize;
