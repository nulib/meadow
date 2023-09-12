import React, { useContext } from "react";

import { Button } from "@nulib/design-system";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { IconDownload } from "@js/components/Icon";
import { ImageDownloader } from "@samvera/image-downloader";
import PropTypes from "prop-types";
import { toastWrapper } from "@js/services/helpers";
import useFileSet from "@js/hooks/useFileSet";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { useWorkDispatch } from "@js/context/work-context";

export function MediaButtons({ fileSet }) {
  const { getWebVttString } = useFileSet();
  const { isAuthorized } = useIsAuthorized();
  const dispatch = useWorkDispatch();
  const [downloadStarted, setDownloadStarted] = React.useState(false);

  const handleDownloadMedia = () => {
    console.log("handleDownloadMedia", handleDownloadMedia);
    // TODO: Call the download media endpoint here

    toastWrapper(
      "is-success",
      `Your media download is being prepared. You will receive an email when it is ready.`
    );

    setDownloadStarted(true);
  };

  if (!fileSet) return null;

  return (
    <div className="buttons is-grouped is-right">
      {isAuthorized() && (
        <Button
          onClick={() =>
            dispatch({
              type: "toggleWebVttModal",
              fileSetId: fileSet?.id,
              webVttString: getWebVttString(fileSet),
            })
          }
        >
          Edit structure (vtt)
        </Button>
      )}
      {/* //TODO: Re-enable once backend is ready to support the link *}
      {/* <Button onClick={handleDownloadMedia} disabled={downloadStarted}>
        <IconDownload />
        Download
      </Button> */}
    </div>
  );
}

export function ImageButtons({ iiifServerUrl, fileSet }) {
  return (
    <div className="field has-addons is-flex is-justify-content-flex-end">
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL_TIFF}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <IconDownload />
          </span>{" "}
          <span>TIF</span>
        </a>
      </p>
      <p className="control">
        <ImageDownloader
          imageUrl={`${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL}`}
          imageTitle={fileSet.accessionNumber}
          className="button"
        >
          JPG
        </ImageDownloader>
      </p>
    </div>
  );
}

const WorkFilesetActionButtonsAccess = ({ fileSet }) => {
  const iiifServerUrl = useContext(IIIFContext);
  const { coreMetadata } = fileSet;
  const isImageType = coreMetadata.mimeType?.includes("image");

  if (isImageType) {
    return <ImageButtons iiifServerUrl={iiifServerUrl} fileSet={fileSet} />;
  }
  if (!isImageType) {
    return <MediaButtons fileSet={fileSet} />;
  }
};

WorkFilesetActionButtonsAccess.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkFilesetActionButtonsAccess;
