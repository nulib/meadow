const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const { S3ClientShim, GetObjectCommand, HeadBucketCommand } = require("aws-s3-shim");
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
      value: result
    };
  }
}

const handler = async (event, _context) => {
  const uri = URI.parse(event.source);

  // Interact with S3 to resolve credentials before trying to generate signed URL
  const s3Client = new S3ClientShim();
  await s3Client.send(new HeadBucketCommand({ Bucket: uri.host }));
  const url = await getSignedUrl( s3Client, new GetObjectCommand({ Bucket: uri.host, Key: uri.path.replace(/^\/+/, "") }) );

  return await extractMediainfoMetadata(url);
};

module.exports = { handler };
