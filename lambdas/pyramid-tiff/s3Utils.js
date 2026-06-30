import {
  S3Client,
  GetObjectCommand,
  HeadObjectCommand,
  PutObjectCommand
} from "@aws-sdk/client-s3";
import { Upload } from "@aws-sdk/lib-storage";

const headObject = async (location) => {
  const s3Location = getS3Location(location);
  const s3Client = new S3Client(s3ClientOpts());
  const { ContentType, Metadata } = await s3Client.send(new HeadObjectCommand(s3Location));
  return { contentType: ContentType, metadata: Metadata };
}

const bufferFromS3 = async (location) => {
  const s3Location = getS3Location(location);
  const s3Client = new S3Client(s3ClientOpts());
  const { Body, ContentType, Metadata } = await s3Client.send(
    new GetObjectCommand(s3Location)
  );
  const buffer = await Body.transformToByteArray();
  return {
    buffer,
    contentType: ContentType ?? "application/octet-stream",
    metadata: Metadata
  };
};

const streamFromS3 = async (location) => {
  const s3Location = getS3Location(location);
  const s3Client = new S3Client(s3ClientOpts());
  const cmd = new GetObjectCommand(s3Location);
  const { Body } = await s3Client.send(cmd);
  return Body;
};

const uploadToS3 = async (data, location, contentType, metadata) => {
  const s3Location = getS3Location(location);
  const s3Client = new S3Client(s3ClientOpts());
  const upload = new Upload({
    client: s3Client,
    params: {
      ...s3Location,
      Body: data,
      ContentType: contentType,
      Metadata: metadata
    }
  });
  await upload.done();
  return location;
};

const getS3Location = (location) => {
  const uri = new URL(location);
  const Bucket = uri.host;
  const Key = uri.pathname.slice(1);
  return { Bucket, Key };
};

const s3ClientOpts = () => {
  const forcePathStyle = process.env.AWS_S3_FORCE_PATH_STYLE === "true";
  const endpoint = process.env.AWS_S3_ENDPOINT;
  return { endpoint, forcePathStyle, httpOptions: { timeout: 600000 } };
};

export { bufferFromS3, headObject, streamFromS3, uploadToS3, getS3Location };