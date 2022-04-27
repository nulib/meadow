import React, { useContext } from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { IconDownload } from "@js/components/Icon";
import { ImageDownloader } from "@samvera/image-downloader";
import { useWorkDispatch } from "@js/context/work-context";
import useFileSet from "@js/hooks/useFileSet";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

function MediaButtons({ fileSet }) {
  const { getWebVttString } = useFileSet();
  const { isAuthorized } = useIsAuthorized();

  const dispatch = useWorkDispatch();
  return (
    <div className="buttons is-flex is-justify-content-flex-end">
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
    </div>
  );
}

function ImageButtons({ iiifServerUrl, fileSet }) {
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
