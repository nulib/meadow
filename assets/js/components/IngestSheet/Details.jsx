import React from "react";
import PropTypes from "prop-types";

function IngestSheetDetails({ totalWorks }) {
  return (
    <div className="content py-3">
      <dl data-testid="ingest-sheet-details">
        <dt>Total works</dt>
        <dd>{totalWorks}</dd>
      </dl>
    </div>
  );
}

IngestSheetDetails.propTypes = {
  totalWorks: PropTypes.number,
};

export default IngestSheetDetails;
