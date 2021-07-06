export default function useFileSet() {
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
    isEmpty,
    isImage,
    isMedia,
  };
}
