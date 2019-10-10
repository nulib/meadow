import React, { useState } from "react";
import WorkRow from "./WorkRow";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { MOCK_INGEST_SHEET_COMPLETED } from "./ingestSheet.query";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";

const IngestSheetCompleted = ({ ingestSheetId }) => {
  const { loading, error, data } = useQuery(MOCK_INGEST_SHEET_COMPLETED, {
    variables: { id: ingestSheetId }
  });
  const [showErrors, setShowErrors] = useState(false);

  if (loading) return "Loading...";
  if (error) return <Error error={error} />;

  const { works = [] } = data.mockIngestSheet;

  return (
    <>
      <div className="my-8">
        <input
          type="checkbox"
          className="mr-2"
          onChange={() => setShowErrors(!showErrors)}
        />
        Show mock errors
      </div>

      {showErrors && (
        <IngestSheetCompletedErrors ingestSheetId={ingestSheetId} />
      )}
      <section>
        {works.length > 0 &&
          works.map(work => <WorkRow key={work.id} work={work} />)}
      </section>
    </>
  );
};

IngestSheetCompleted.propTypes = {
  ingestSheetId: PropTypes.string
};

export default IngestSheetCompleted;
