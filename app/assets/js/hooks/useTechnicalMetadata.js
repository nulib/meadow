export default function useTechnicalMetadata() {
  function getTechnicalMetadata(fileSet = {}) {
    if (Object.keys(fileSet).length === 0) return;

    try {
      const extracted = JSON.parse(fileSet.extractedMetadata);
      const mimeType = fileSet.coreMetadata?.mimeType?.toLowerCase();
      if (!mimeType) return;

      const isMedia = mimeType.includes("video") || mimeType.includes("audio");
      const isImage = mimeType.includes("image");

      if (isMedia) {
        // Return Audio or Video technical metadata
        return extracted.mediainfo.value.media.track;
      } else if (isImage) {
        // Return Image technical metadata
        return extracted.exif?.value;
      }
    } catch (e) {
      console.error("Error extracting extractedMetadata from an AV fileset", e);
    }
  }

  return {
    getTechnicalMetadata,
  };
}
