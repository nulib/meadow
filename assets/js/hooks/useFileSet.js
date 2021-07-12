export default function useFileSet() {
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

  return {
    getWebVttString,
    isEmpty,
    isImage,
    isMedia,
  };
}
