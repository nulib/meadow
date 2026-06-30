import "source-map-support/register.js";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import {
  S3Client,
  GetObjectCommand,
  HeadBucketCommand
} from "@aws-sdk/client-s3";
import URI from "uri-js";
import { promisify } from "util";
import { exec as execCallback } from "child_process";

const mediainfoPath = process.env.MEDIAINFO_PATH || "mediainfo";
const exec = promisify(execCallback);

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
  const result = JSON.parse(stdout);

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

const s3ClientOpts = () => {
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === "true";
  const endpoint = process.env.AWS_S3_ENDPOINT;
  return { endpoint, forcePathStyle, httpOptions: { timeout: 600000 } };
};

const handler = async (event, _context) => {
  const uri = URI.parse(event.source);

  // Interact with S3 to resolve credentials before trying to generate signed URL
  const s3Client = new S3Client(s3ClientOpts());
  await s3Client.send(new HeadBucketCommand({ Bucket: uri.host }));
  const url = await getSignedUrl(
    s3Client,
    new GetObjectCommand({
      Bucket: uri.host,
      Key: uri.path.replace(/^\/+/, "")
    })
  );

  return await extractMediainfoMetadata(url);
};

export { handler };
