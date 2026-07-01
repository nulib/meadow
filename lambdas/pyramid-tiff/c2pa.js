import { bufferFromS3, headObject } from "./s3Utils.js";
import {
  SecretsManagerClient,
  GetSecretValueCommand
} from "@aws-sdk/client-secrets-manager";
import {
  Builder,
  LocalSigner,
  Reader,
  createVerifySettings
} from "@contentauth/c2pa-node";

const getc2paSigningCert = async () => {
  try {
    const secretName = `${process.env.SECRETS_PATH}/config/c2pa_cert`;
    const secretsClient = new SecretsManagerClient({});
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await secretsClient.send(command);
    return JSON.parse(response.SecretString);
  } catch (err) {
    if (err.name === "ResourceNotFoundException") {
      console.error("C2PA signing certificate not found. Skipping signing of content credentials.");
    }
    return {};
  }
};

const getActiveReaderFromSidecar = async (source) => {
  const sidecarLocation = `${source}.c2pa`;
  try {
    await headObject(sidecarLocation);
    await headObject(source);
  } catch (err) {
    if (err.name === "NotFound") return null;
    throw err;
  }

  const { buffer: manifestData } = await bufferFromS3(sidecarLocation);
  const { buffer, contentType: mimeType } = await bufferFromS3(source);
  const sidecarReader = await Reader.fromManifestDataAndAsset(manifestData, {
    buffer,
    mimeType
  });
  const manifest = sidecarReader.getActive();

  const rebuilder = Builder.withJson(
    manifest,
    createVerifySettings({ verifyAfterSign: false, verifyTrust: false })
  );
  if (manifest?.thumbnail) {
    const { buffer: thumbBuffer } = await sidecarReader.resourceToAsset(
      manifest.thumbnail.identifier,
      { buffer: null }
    );
    await rebuilder.addResource(manifest.thumbnail.identifier, {
      buffer: thumbBuffer,
      mimeType: manifest.thumbnail.format
    });
  }

  const { certificate: cert, key } = await getc2paSigningCert();
  const signer = LocalSigner.newSigner(
    Buffer.from(cert),
    Buffer.from(key),
    "es256"
  );
  const output = { buffer: null };
  rebuilder.sign(signer, { buffer, mimeType }, output);

  const reader = await Reader.fromAsset({ buffer: output.buffer, mimeType });
  return { reader, buffer: output.buffer, mimeType };
};

const getActiveReaderFromSource = async (source) => {
  const { buffer, contentType } = await bufferFromS3(source);
  const reader = await Reader.fromAsset({ buffer, mimeType: contentType });
  return { reader, buffer, mimeType: contentType };
}

const getActiveReader = async (source) => {
  return await getActiveReaderFromSidecar(source) || await getActiveReaderFromSource(source);
}

const addContentCredentials = async (data, intent, actions, opts) => {
  const { parentLocation, manifestOnly, mimeType } = opts || {};
  const { certificate: cert, key } = await getc2paSigningCert();
  if (!cert || !key) return data;

  const builder = Builder.new();
  builder.setIntent(intent);

  if (parentLocation) {
    const { reader, buffer, mimeType } = await getActiveReader(parentLocation);
    try {
      await builder.addIngredientFromReader(reader);
    } catch (err) {
      if (!reader || err.message.includes("ingredient file not found")) {
        console.warn(`addIngredientFromReader failed for ${parentLocation} , adding ingredient from buffer instead`);
        const manifest = reader?.getActive();
        
        const ingredientContent = {
          title: manifest?.title || new URL(parentLocation).pathname.split("/").pop(),
          format: manifest?.format || mimeType,
          instance_id: manifest?.instance_id,
          relationship: "parentOf"
        };

        await builder.addIngredient(JSON.stringify(ingredientContent), { buffer, mimeType });
      } else {
        throw err;
      }
    }
  }

  builder.addAssertion(
    "c2pa.actions",
    {
      actions: actions || []
    },
    "Cbor"
  );

  const signer = LocalSigner.newSigner(
    Buffer.from(cert),
    Buffer.from(key),
    "es256"
  );

  const output = { buffer: null };

  if (manifestOnly) {
    builder.noEmbed = true;
  }
  const manifestData = await builder.sign(signer, { buffer: data, mimeType: mimeType }, output);
  return manifestOnly ? manifestData : output.buffer;
};

export { addContentCredentials, getActiveReader };
