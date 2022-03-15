const AWS = require("aws-sdk");
const authorize = require("./authorize");
const allowedReferers = process?.env?.ALLOWED_REFERERS || "${allowed_referers}";

const handler = async (event, _context) => {
  console.log("Initiating stream authorization");
  const request = event.Records[0].cf.request;
  const path = decodeURI(request.uri.replace(/%2f/gi, ""));
  const id = path.split("/").slice(0, -1).join("");
  console.log("Streaming resource ID", id);
  const referer = request?.headers?.referer?.[0]?.value;
  if (referer && new RegExp(allowedReferers).test(referer)) {
    console.log("Stream authorized: originated from an authorized referer");
    return request;
  }
  const isOpen = await authorize(id);

  if (isOpen) {
    console.log(
      `Stream authorized: found $${id} with open visibility in Elasticsearch`
    );
    return request;
  }

  const response = {
    status: "403",
    statusDescription: "Forbidden",
    body: "Forbidden",
  };
  console.log(`Stream unauthorized for $${id}, returning forbidden response`);
  return response;
};

module.exports = { handler };
