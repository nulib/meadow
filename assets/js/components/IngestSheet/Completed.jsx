import React, { useState } from "react";
import WorkRow from "../Work/Row";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { INGEST_SHEET_WORKS } from "./ingestSheet.query";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import IngestSheetDownload from "./Completed/Download";

const IngestSheetCompleted = ({ sheetId }) => {
  const { loading, error, data } = useQuery(INGEST_SHEET_WORKS, {
    variables: { id: sheetId }
  });
  const [showErrors, setShowErrors] = useState(false);

  if (loading) return "Loading...";
  if (error) return <Error error={error.message} />;

  const works = data.ingestSheetWorks;

  return (
    <>
      <IngestSheetDownload sheetId={sheetId} />
      <div className="my-8">
        <input
          type="checkbox"
          className="mr-2"
          onChange={() => setShowErrors(!showErrors)}
        />
        Show mock errors
      </div>

      {showErrors && <IngestSheetCompletedErrors sheetId={sheetId} />}
      <section>
        {works.length > 0 &&
          works.map(work => <WorkRow key={work.id} work={work} />)}
      </section>
    </>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string
};

export default IngestSheetCompleted;
