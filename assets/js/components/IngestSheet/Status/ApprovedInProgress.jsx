import React from "react";
import UIProgressBar from "../../UI/UIProgressBar";
import PropTypes from "prop-types";

const IngestSheetStatusApprovedInProgress = ({ ingestSheet }) => {
  return (
    <section>
      <div className="pt-12">
        <UIProgressBar percentComplete={50} label="works being created" />
      </div>
      <div className="text-center leading-loose text-gray-600">
        <p>48 works are being created</p>
        <p>370 file sets are being created</p>
        <p>What other info goes here?</p>
      </div>
    </section>
  );
};

IngestSheetStatusApprovedInProgress.propTypes = {
  ingestSheet: PropTypes.object
};

export default IngestSheetStatusApprovedInProgress;
