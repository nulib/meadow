const AWS = require("aws-sdk");
const URI = require("uri-js");
const mediainfoPath = process.env.MEDIAINFO_PATH || "mediainfo";
const util = require("util");
const exec = util.promisify(require("child_process").exec);

async function mediainfoVersion() {
  const { stdout, _stderr } = await exec(`${mediainfoPath} --Version`);
  return stdout.includes("- v")
    ? stdout.substring(stdout.indexOf("- v") + 3).trim()
    : "unknown";
}

async function extractMediainfoMetadata(url) {
  const version = await mediainfoVersion();

  const { stdout, _stderr } = await exec(
    `${mediainfoPath} --Full --Output=JSON "${url}"`
  );
  result = JSON.parse(stdout);

  if (result.media == null) {
    throw "404 Not Found";
  } else {
    return {
      tool: "mediainfo",
      tool_version: version,
      value: result,
    };
  }
}

const handler = async (event, _context) => {
  const uri = URI.parse(event.source);
  const s3Location = {
    Bucket: uri.host,
    Key: uri.path.replace(/^\/+/, ""),
  };
  const s3 = new AWS.S3();
  const url = s3.getSignedUrl("getObject", s3Location);

  return await extractMediainfoMetadata(url);
};

module.exports = { handler };
