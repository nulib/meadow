export default function useFileSet() {
  /**
   * Helper function which separates file sets by role
   */
  function filterFileSets(fileSets = []) {
    const returnObj = {
      access: fileSets.filter((fs) => fs.role.id === "A"),
      auxiliary: fileSets.filter((fs) => fs.role.id === "X"),
    };
    return returnObj;
  }

  function getWebVttString(fileSet = {}) {
    if (isEmpty(fileSet)) return "";
    let webVtt =
      fileSet.structuralMetadata?.type === "WEBVTT"
        ? fileSet.structuralMetadata.value
        : "";
    return webVtt;
  }

  function isEmpty(fileSet = {}) {
    return !fileSet || Object.keys(fileSet).length === 0;
  }

  function isAltFormat(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    const acceptedTypes = [
      "application/pdf",
      "application/zip",
      "application/zip-compressed",
    ];
    return acceptedTypes.includes(mimeType);
  }

  function isImage(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    return mimeType.includes("image");
  }

  function isMedia(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    return mimeType.includes("video") || mimeType.includes("audio");
  }

  function isPDF(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    return mimeType === "application/pdf";
  }

  function isVideo(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    return mimeType.includes("video");
  }

  function isZip(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    return mimeType.includes("zip");
  }

  function altFileFormat(fileSet = {}) {
    const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
    if (!mimeType) return;
    if (mimeType === "application/pdf") {
      return "pdf";
    } else {
      return "zip";
    }
  }

  return {
    altFileFormat,
    filterFileSets,
    getWebVttString,
    isAltFormat,
    isEmpty,
    isImage,
    isMedia,
    isPDF,
    isVideo,
    isZip,
  };
}
