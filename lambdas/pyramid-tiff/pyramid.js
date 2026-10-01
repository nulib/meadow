import { addContentCredentials } from "./c2pa.js";
import { streamFromS3, uploadToS3 } from "./s3Utils.js";
import concat from "concat-stream";
import sharp from "sharp";

const MAX_DIMENSION = 15000;
const TILE_SIZE = 256;

const createPyramidTiff = async (source, dest, opts = {}) => {
  console.log(`Creating pyramid from ${source}`);
  const inputStream = await streamFromS3(source);

  const transformStream = sharp({
    limitInputPixels: false,
    sequentialRead: true,
    unlimited: true
  })
    .removeAlpha()
    .resize({
      width: MAX_DIMENSION,
      height: MAX_DIMENSION,
      fit: "inside",
      withoutEnlargement: true
    })
    .rotate()
    .tiff({
      compression: "jpeg",
      quality: 75,
      tile: true,
      tileHeight: TILE_SIZE,
      tileWidth: TILE_SIZE,
      pyramid: true
    })
    .withMetadata();

  // concat-stream is callback-only, so an explicit Promise is required here
  let data = await new Promise((resolve, reject) => {
    inputStream.pipe(transformStream).pipe(concat(resolve));
  });

  const preMetadata = await transformStream.metadata();
  const postMetadata = await sharp(data).metadata();
  
  const actions = [];

  if (preMetadata.hasAlpha && !postMetadata.hasAlpha) {
    actions.push({
      action: "c2pa.edited",
      softwareAgent: "Meadow (https://github.com/nulib/meadow)",
      parameters: {
        description: "Alpha channel removed"
      }
    });
  }

  if (preMetadata.width > MAX_DIMENSION || preMetadata.height > MAX_DIMENSION) {
    actions.push({
      action: "c2pa.resized",
      softwareAgent: "Meadow (https://github.com/nulib/meadow)",
      parameters: {
        description: `Resized to ${postMetadata.width}×${postMetadata.height}px`
      }
    });
  }

  if (preMetadata.orientation && preMetadata.orientation !== postMetadata.orientation) {
    actions.push({
      action: "c2pa.orientation",
      softwareAgent: "Meadow (https://github.com/nulib/meadow)",
      parameters: {
        description: `Auto-rotated to EXIF orientation ${postMetadata.orientation}`
      }
    });
  }

  actions.push({
    action: "c2pa.transcoded",
    softwareAgent: "Meadow (https://github.com/nulib/meadow)",
    parameters: {
      description: `Tiled pyramidal TIFF, tile size ${TILE_SIZE}×${TILE_SIZE}px, JPEG compression quality 75`
    }
  });

  data = await addContentCredentials(data, "edit", actions, { parentLocation: source, mimeType: "image/tiff", title: opts.title });

  console.log(`Saving to ${dest}`);
  const { width, height, pages } = await sharp(data).metadata();
  const metadata = {
    width: width.toString(),
    height: height.toString(),
    pages: pages.toString(),
    tilesize: TILE_SIZE.toString()
  };
  return uploadToS3(data, dest, "image/tiff", metadata);
};

export { createPyramidTiff };
