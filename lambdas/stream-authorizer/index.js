import authorize from "./authorize.js";
import middy from "@middy/core";
import secretsManager from "@middy/secrets-manager";

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

async function viewerRequestHandler(event, { config }) {
  console.log("Initiating stream authorization");
  const request = event.Records[0].cf.request;

  const path = decodeURIComponent(request.uri);
  const uuidRe =
    /(?<uuid>[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})/;
  const id = uuidRe.exec(path.split("/").join(""))?.groups?.uuid;

  console.log("Streaming resource ID", id);
  const referer = getEventHeader(request, "referer");
  const cookie = getEventHeader(request, "cookie");
  const allowed = await authorize(id, referer, cookie, config);

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

async function requestHandler(event, context) {
  const { eventType } = event.Records[0].cf.config;

  switch (eventType) {
    case "viewer-request":
      return await viewerRequestHandler(event, context);
    case "viewer-response":
      return await viewerResponseHandler(event);
    default:
      return event.Records[0].cf.request;
  }
}

function functionNameAndRegion() {
  let nameVar = process.env.AWS_LAMBDA_FUNCTION_NAME;
  const match = /^(?<functionRegion>[a-z]{2}-[a-z]+-\d+)\.(?<functionName>.+)$/.exec(nameVar);
  if (match) {
    return { ...match.groups }
  } else {
    return {
      functionName: nameVar,
      functionRegion: process.env.AWS_REGION
    }
  }
}

const { functionName, functionRegion } = functionNameAndRegion();

export const handler = 
  middy()
    .use(
      secretsManager({
        fetchData: { config: functionName },
        awsClientOptions: { region: functionRegion },
        setToContext: true
      })
    )
    .handler(requestHandler);
