import { bufferFromS3, headObject } from "./s3Utils.js";
import {
  SecretsManagerClient,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager";
import { loadC2paNode, signAsset } from "@nulib/c2pa-signing";

let credentials;

// Fetched once per container rather than per invocation.
const getSigningCredentials = () => {
  credentials ??= (async () => {
    try {
      const secretName = `${process.env.SECRETS_PATH}/config/c2pa_cert`;
      const secretsClient = new SecretsManagerClient({});
      const response = await secretsClient.send(new GetSecretValueCommand({ SecretId: secretName }));
      const { certificate, key, tsa_url } = JSON.parse(response.SecretString);
      return { certificate, key, tsaUrl: tsa_url };
    } catch (err) {
      if (err.name === "ResourceNotFoundException") {
        console.error("C2PA signing certificate not found. Skipping signing of content credentials.");
      }
      credentials = undefined; // retry on the next invocation
      return {};
    }
  })();
  return credentials;
};

const exists = async (location) => {
  try {
    await headObject(location);
    return true;
  } catch (err) {
    if (err.name === "NotFound") return false;
    throw err;
  }
};

// Preservation files carry their content credentials in a sidecar manifest at
// `<location>.c2pa`. Returns null if the parent has no sidecar.
const getParent = async (location) => {
  const sidecarLocation = `${location}.c2pa`;
  if (!(await exists(sidecarLocation))) return null;

  const [{ buffer: manifest }, { buffer: asset, contentType: mimeType }] = await Promise.all([
    bufferFromS3(sidecarLocation),
    bufferFromS3(location)
  ]);
  return {
    asset: Buffer.from(asset),
    mimeType,
    manifest: Buffer.from(manifest),
    title: new URL(location).pathname.split("/").pop()
  };
};

/**
 * Signs `data`, returning the signed asset -- or, with `manifestOnly`, a
 * sidecar manifest for the unchanged asset.
 *
 * With `parentLocation`, the manifest chains to that parent via its sidecar.
 * A parent without a sidecar has no provenance to carry forward, so `data` is
 * returned unsigned (with a warning) rather than signed with an unverifiable
 * ingredient.
 */
const addContentCredentials = async (data, intent, actions, opts) => {
  const { parentLocation, manifestOnly, mimeType, title } = opts || {};
  const { certificate, key, tsaUrl } = await getSigningCredentials();
  console.info(`Signing with certificate: ${certificate ? "present" : "missing"}, key: ${key ? "present" : "missing"}, tsaUrl: ${tsaUrl || "missing"}`);
  if (!certificate || !key) return data;

  let parent;
  if (parentLocation) {
    parent = await getParent(parentLocation);
    if (!parent) {
      console.warn(`No C2PA sidecar found for ${parentLocation}; returning content without content credentials.`);
      return data;
    }
  }

  const result = await signAsset({
    asset: Buffer.from(data),
    mimeType,
    title,
    intent,
    actions: actions || [],
    parent,
    output: manifestOnly ? "sidecar" : "embedded",
    credentials: { certificate, key, tsaUrl }
  });
  return manifestOnly ? result.manifest : result.asset;
};

/** A Reader for `source`, using its sidecar manifest if it has one. */
const getActiveReader = async (source) => {
  const { Reader } = await loadC2paNode();
  const parent = await getParent(source);
  if (parent) {
    const { asset: buffer, mimeType, manifest } = parent;
    const reader = await Reader.fromManifestDataAndAsset(manifest, { buffer, mimeType });
    return { reader, buffer, mimeType };
  }
  const { buffer, contentType: mimeType } = await bufferFromS3(source);
  const reader = await Reader.fromAsset({ buffer: Buffer.from(buffer), mimeType });
  return { reader, buffer, mimeType };
};

export { addContentCredentials, getActiveReader };
