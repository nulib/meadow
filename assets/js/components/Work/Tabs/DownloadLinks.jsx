import React, { useContext } from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { IIIFContext } from "../../IIIF/IIIFProvider";
import { IIIF_SIZES } from "../../../services/global-vars";

const WorkTabsDownloadLinks = ({ handleDownloadClick, fileSetId }) => {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <div className="field has-addons is-pulled-right">
      <p className="control">
        <button className="button" onClick={() => handleDownloadClick("TIFF")}>
          <span className="icon">
            <FontAwesomeIcon icon="file-download" />
          </span>{" "}
          <span>TIFF</span>
        </button>
      </p>
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileSetId}${IIIF_SIZES.IIIF_FULL}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <FontAwesomeIcon icon="file-download" />
          </span>{" "}
          <span>JPG</span>
        </a>
      </p>
    </div>
  );
};

WorkTabsDownloadLinks.propTypes = {
  handleDownloadClick: PropTypes.func,
  fileSetId: PropTypes.string,
};

export default WorkTabsDownloadLinks;
