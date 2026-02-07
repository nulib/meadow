const { S3Client, GetObjectCommand } = require("@aws-sdk/client-s3");
const FileType = require("file-type");
const path = require("path");


const handler = async (event, _context, _callback) => {
  return await extractMimeType(event);
};

const readBody = (Body) => {
  return new Promise((resolve, _reject) => {
    Body.on("readable", () => {
      resolve(Body.read());
    });
  });
};

const extractMimeType = async (event) => {
  try {
    const s3Client = new S3Client(s3ClientOpts());
    const cmd = new GetObjectCommand({
      Bucket: event.bucket,
      Key: event.key,
      Range: "bytes=0-1023"
    });
    const { Body } = await s3Client.send(cmd);
    const firstK = await readBody(Body);

    // response: {"ext":"jpg","mime":"image/jpeg"}
    const fileType = await FileType.fromBuffer(firstK);
    if (fileType) {
      console.log('identified file as', JSON.stringify(fileType));
      return { ...fileType, verified: true };  
    } else {
      return fallback(event);
    }
  } catch (e) {
    console.error("Error extracting mime-type");
    return Promise.reject(e);
  }
};

const fallback = (event) => {
  const ext = path.extname(event.key).replace(/^\./, "");
  const mime = event.fallback;

  if (mime === undefined) 
    return { ext, mime: "application/octet-stream", verified: false }

  if (mime && (! mime.match(/xml$/)) && FileType.mimeTypes.has(mime)) {
    console.warn(`${path.basename(event.key)} attempting to fall back to ${mime} but magic number doesn't match.`);
    return undefined;
  }

  return {
    ext: path.extname(event.key).replace(/^\./, ""),
    mime: mime,
    verified: false
  }
}

const s3ClientOpts = () => {
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === "true";
  const endpoint = process.env.AWS_S3_ENDPOINT;
  return { endpoint, forcePathStyle, httpOptions: { timeout: 600000 } };
};

module.exports = { handler };
