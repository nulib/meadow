import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { ImageDownloader } from "@samvera/image-downloader";
import { Button } from "@nulib/admin-react-components";

const WorkFilesetActionButtonsAccess = ({ fileSet }) => {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <div className="buttons is-flex is-justify-content-flex-end">
      <Button>View Aux File</Button>
      <ImageDownloader
        imageUrl={`${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL}`}
        imageTitle={fileSet.accessionNumber}
        className="button"
      >
        Download JPG
      </ImageDownloader>
    </div>
  );
};

WorkFilesetActionButtonsAccess.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkFilesetActionButtonsAccess;
