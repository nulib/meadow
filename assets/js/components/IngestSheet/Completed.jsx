import React, { useState } from "react";
import WorkRow from "../Work/Row";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { INGEST_SHEET_WORKS } from "./ingestSheet.query";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import IngestSheetDownload from "./Completed/Download";
import WorkListItem from "../Work/ListItem";

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
      {/* <IngestSheetDownload sheetId={sheetId} /> */}
      <p>
        <label className="checkbox">
          <input type="checkbox" onChange={() => setShowErrors(!showErrors)} />
          Show errors
        </label>
      </p>

      {showErrors && <IngestSheetCompletedErrors sheetId={sheetId} />}
      <section className="section">
        <div className="columns is-multiline">
          {works.map(work => (
            <div
              key={work.id}
              className="column is-half-tablet is-one-third-desktop"
            >
              <WorkListItem key={work.id} work={work} />
            </div>
          ))}
        </div>
      </section>
    </>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string
};

export default IngestSheetCompleted;
