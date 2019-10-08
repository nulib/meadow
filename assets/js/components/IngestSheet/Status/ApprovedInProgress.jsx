import React, { useEffect } from "react";
import UIProgressBar from "../../UI/UIProgressBar";
import PropTypes from "prop-types";
import { useSubscription } from "@apollo/react-hooks";
import { MOCK_WORKS_CREATED_COUNT_SUBSCRIPTION } from "../ingestSheet.query";

const IngestSheetStatusApprovedInProgress = ({ ingestSheet }) => {
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

  return (
    <section>
      <div className="pt-12">
        <UIProgressBar
          percentComplete={mockPercentComplete()}
          progressValue={mockPercentComplete() / 10}
          isProgressValueAPercentage={false}
          label="works being created"
        />
      </div>
      <div className="text-center leading-loose text-gray-600">
        <p>
          {!loading && data.mockWorksCreatedCount.count} works are being created
        </p>
        <p>xxx file sets are being created</p>
        <p>What other helpful info could go here?</p>
      </div>
    </section>
  );
};

IngestSheetStatusApprovedInProgress.propTypes = {
  ingestSheet: PropTypes.object
};

export default IngestSheetStatusApprovedInProgress;
