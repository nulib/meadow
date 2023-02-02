const authorize = require("./authorize");

function getEventHeader(request, header) {
  return request?.headers?.[header]?.[0]?.value;
}

function addAccessControlHeaders(request, response) {
  const origin = getEventHeader(request, "origin") || "*";
  if (!response.headers) response.headers = {};
  response.headers["access-control-allow-origin"] = [
    { key: "Access-Control-Allow-Origin", value: origin },
  ];
  response.headers["access-control-allow-headers"] = [
    { key: "Access-Control-Allow-Headers", value: "authorization, cookie" },
  ];
  response.headers["access-control-allow-credentials"] = [
    { key: "Access-Control-Allow-Credentials", value: "true" },
  ];
  return response;
}

async function viewerRequestHandler(event) {
  console.log("Initiating stream authorization");
  const request = event.Records[0].cf.request;

  const path = decodeURIComponent(request.uri);
  const uuidRe =
    /(?<uuid>[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})/;
  const id = uuidRe.exec(path.split("/").join(""))?.groups?.uuid;

  console.log("Streaming resource ID", id);
  const referer = getEventHeader(request, "referer");
  const cookie = getEventHeader(request, "cookie");
  const allowed = await authorize(id, referer, cookie);

  if (allowed) return request;

  const response = {
    status: "403",
    statusDescription: "Forbidden",
    body: "Forbidden",
  };
  return response;
}

async function viewerResponseHandler(event) {
  const { request, response } = event.Records[0].cf;
  return addAccessControlHeaders(request, response);
}

async function handler(event) {
  const { eventType } = event.Records[0].cf.config;

  switch (eventType) {
    case "viewer-request":
      return await viewerRequestHandler(event);
    case "viewer-response":
      return await viewerResponseHandler(event);
    default:
      return event.Records[0].cf.request;
  }
}

module.exports = {
  handler,
};
