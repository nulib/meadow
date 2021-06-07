import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { ImageDownloader } from "@samvera/image-downloader";

const WorkFilesetActionButtonsAuxiliary = ({ fileSet }) => {
  const iiifServerUrl = useContext(IIIFContext);
  const url = `${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL}`;

  return (
    <div className="buttons is-flex is-justify-content-flex-end">
      <a className="button" href={url} target="_blank">
        View Aux File
      </a>
      <ImageDownloader
        imageUrl={url}
        imageTitle={fileSet.accessionNumber}
        className="button"
      >
        Download JPG
      </ImageDownloader>
    </div>
  );
};

WorkFilesetActionButtonsAuxiliary.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkFilesetActionButtonsAuxiliary;
