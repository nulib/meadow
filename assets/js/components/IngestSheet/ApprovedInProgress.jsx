import React, { useEffect } from "react";
import UIProgressBar from "../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/react-hooks";
import { INGEST_PROGRESS_SUBSCRIPTION } from "./ingestSheet.query";

const IngestSheetApprovedInProgress = ({ ingestSheet }) => {
  const { data, loading, error } = useSubscription(
    INGEST_PROGRESS_SUBSCRIPTION,
    {
      variables: { sheetId: ingestSheet.id }
    }
  );

  if (loading) return <p>...Loading</p>;
  if (error) {
    console.log(error);
    return <p>Error: {error.message}</p>;
  }

  const { ingestProgress } = data;
  return (
    <section>
      <div className="pt-12">
        <UIProgressBar
          percentComplete={ingestProgress.percentComplete}
          progressValue={ingestProgress.completedFileSets}
          totalValue={ingestProgress.totalFileSets}
          isProgressValueAPercentage={false}
          label="file sets have been processed"
        />
      </div>
      <div className="text-center leading-loose text-gray-600">
        <p></p>
      </div>
    </section>
  );
};

IngestSheetApprovedInProgress.propTypes = {
  ingestSheet: PropTypes.object
};

export default IngestSheetApprovedInProgress;
