import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "../../IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { IconDownload } from "@js/components/Icon";
import { ImageDownloader } from "@samvera/image-downloader";

const WorkTabsDownloadLinks = ({ handleDownloadClick, fileset }) => {
  const iiifServerUrl = useContext(IIIFContext);

  return (
    <div className="field has-addons is-pulled-right">
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileset.id}${IIIF_SIZES.IIIF_FULL_TIFF}`}
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
        <ImageDownloader
          imageUrl={`${iiifServerUrl}${fileset.id}${IIIF_SIZES.IIIF_FULL}`}
          imageTitle={fileset.accessionNumber}
          className="button"
        >
          JPG
        </ImageDownloader>
        {/* <a
          href={`${iiifServerUrl}${fileSetId}${IIIF_SIZES.IIIF_FULL}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <IconDownload />
          </span>{" "}
          <span>JPG</span>
        </a> */}
      </p>
    </div>
  );
};

WorkTabsDownloadLinks.propTypes = {
  handleDownloadClick: PropTypes.func,
  fileSet: PropTypes.object,
};

export default WorkTabsDownloadLinks;
