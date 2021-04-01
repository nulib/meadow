import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "../../IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { IconDownload } from "@js/components/Icon";

const WorkTabsDownloadLinks = ({ handleDownloadClick, fileSetId }) => {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <div className="field has-addons is-pulled-right">
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileSetId}${IIIF_SIZES.IIIF_FULL_TIFF}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <IconDownload />
          </span>{" "}
          <span>TIFF</span>
        </a>
      </p>
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileSetId}${IIIF_SIZES.IIIF_FULL}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <IconDownload />
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
