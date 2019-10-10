import React, { useEffect } from "react";
import UIProgressBar from "../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/react-hooks";
import { MOCK_WORKS_CREATED_COUNT_SUBSCRIPTION } from "./ingestSheet.query";

const IngestSheetApprovedInProgress = ({ ingestSheet }) => {
  const { data, loading, error } = useSubscription(
    MOCK_WORKS_CREATED_COUNT_SUBSCRIPTION,
    {
      variables: { sheetId: ingestSheet.id }
    }
  );

  if (loading) return <p>...Loading</p>;
  if (error) return <p>Error: {error}</p>;

  const mockPercentComplete = () => {
    const mockTotalWorkCount = 10;
    return (data.mockWorksCreatedCount.count / mockTotalWorkCount) * 100;
  };

  const mockProgressValue = () => {
    return data.mockWorksCreatedCount.count;
  };

  return (
    <section>
      <div className="pt-12">
        <UIProgressBar
          percentComplete={mockPercentComplete()}
          progressValue={mockProgressValue()}
          isProgressValueAPercentage={false}
          label="works have been created"
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
