import * as globalVars from "./global-vars";

function buildDisplayIIIFUrl(rootUrl, iiifRegion) {
  return rootUrl ? `${rootUrl}${iiifRegion}` : "";
}

/**
 * Put together all the data which carousels need to load and display proper data
 * @param  {array} manifests An array of 2.0 IIIF manifests
 * @return {array} An array of objects which contain data that will feed a carousel
 */
export function constructCarouselItems(manifests) {
  // Create helper object from each manifest listing out the (label, description, metadata, and imageUrl) from IIIF manifest
  const items = manifests.map(manifest => {
    const { label, description, metadata } = manifest;
    let obj = {
      label,
      description,
      metadata
    };
    const iiifRootUrl = getIIIFRootUrl(manifest);

    obj.id = manifest["@id"];
    obj.imageUrl = buildDisplayIIIFUrl(
      iiifRootUrl,
      globalVars.IIIF_SMALL_ITEM_REGION
    );
    return obj;
  });

  return items;
}

/**
 * Parse the root IIIF url from a manifest
 * @param  {Object} manifest IIIF manifest
 * @return {String} Root url string.  Or empty string if there was a parsing error pulling the root url from manifest.
 */
function getIIIFRootUrl(manifest) {
  let iiifRootUrl;

  try {
    iiifRootUrl =
      manifest.sequences[0].canvases[0].images[0].resource.service["@id"];
  } catch (err) {
    iiifRootUrl = "";
  }
  return iiifRootUrl;
}

/**
 * Extract tile source urls from a IIIF manifest
 * @param {object} manifest
 * @returns {array}
 */
export function getTileSources(manifest) {
  let tileSources = [];

  if (!manifest.sequences || !manifest.sequences[0].canvases) {
    return tileSources;
  }

  manifest.sequences[0].canvases.forEach(canvas => {
    if (canvas.images.length > 0 && canvas.images[0].resource) {
      tileSources.push({
        id: canvas.images[0].resource.service["@id"],
        label: canvas.label
      });
    }
  });

  return tileSources;
}
