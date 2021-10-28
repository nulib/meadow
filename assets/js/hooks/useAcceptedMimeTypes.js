// Good ref site:  https://www.digipres.org/formats/mime-types/

export default function useAcceptedMimeTypes() {
  function isFileValid(fileSetRole, workTypeId, mimeType) {
    if (!fileSetRole || !workTypeId || !mimeType) {
      return { isValid: false };
    }

    const mimeParts = mimeType.split("/");
    const isImage = mimeParts[0] === "image";
    const isAudio = mimeParts[0] === "audio";
    const isVideo = mimeParts[0] === "video";
    let code = "";
    let message = "";
    let isValid = true;

    switch (fileSetRole) {
      case "S":
        return { code, message, isValid };

      case "X":
        if (!isImage) {
          isValid = false;
          code = "invalid-image";
          message = "Auxiliary files can only be image mime types";
        }
        break;

      case "A":
        switch (workTypeId) {
          case "IMAGE":
            if (!isImage) {
              isValid = false;
              code = "invalid-image";
              message =
                "Image work types Access fileset roles must be image mime type";
            }
            break;
          case "AUDIO":
            if (mimeType.includes("aiff") || mimeType.includes("flac")) {
              isValid = false;
              code = "invalid-audio";
              message =
                "Audio work types Access filesets cannot be .aiff or .flac mime types";
            } else if (!isAudio) {
              isValid = false;
              code = "invalid-audio";
              message =
                "Audio work types Access filesets must be audio mime type";
            }
            break;
          case "VIDEO":
            if (mimeType.includes("matroska")) {
              isValid = false;
              code = "invalid-video";
              message =
                "Video work types Access filesets cannot be *matroska mime type";
            } else if (!isVideo) {
              isValid = false;
              code = "invalid-video";
              message =
                "Video work types Access filesets must be video mime type";
            }
            break;
          default:
            console.error(`Invalid work type id: ${workTypeId}`);
            isValid = false;
            code = "invalid-work-type";
            message = "Work type is invalid";
            break;
        }
        break;
      case "P":
        switch (workTypeId) {
          case "IMAGE":
            if (!isImage) {
              isValid = false;
              code = "invalid-image";
              message =
                "Image work types Preservation fileset roles must be image mime type";
            }
            break;
          case "AUDIO":
            if (!isAudio) {
              isValid = false;
              code = "invalid-audio";
              message =
                "Audio work types Preservation fileset roles must be audio mime type";
            }
            break;
          case "VIDEO":
            if (!isVideo) {
              isValid = false;
              code = "invalid-video";
              message =
                "Video work types Preservation fileset roles must be video mime type";
            }
            break;
          default:
            console.error(`Invalid work type id: ${workTypeId}`);
            isValid = false;
            code = "invalid-work-type";
            message = "Work type is invalid";
            break;
        }
        break;
      default:
        console.error(`Invalid file set role: ${fileSetRole}`);
        isValid = false;
        code = "invalid-fileset-role";
        message = "Fileset role is invalid";
        break;
    }

    return { code, isValid, message };
  }

  return { isFileValid };
}
