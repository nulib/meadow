import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const WorkTabsDownloadLinks = ({ handleDownloadClick }) => {
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
        <button className="button" onClick={() => handleDownloadClick("JPG")}>
          <span className="icon">
            <FontAwesomeIcon icon="file-download" />
          </span>{" "}
          <span>JPG</span>
        </button>
      </p>
    </div>
  );
};

WorkTabsDownloadLinks.propTypes = {
  handleDownloadClick: PropTypes.func,
};

export default WorkTabsDownloadLinks;
