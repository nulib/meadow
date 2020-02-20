import React, { useState } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS
} from "./ingestSheet.query";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import WorkListItem from "../Work/ListItem";

const IngestSheetCompleted = ({ sheetId }) => {
  const {
    loading: worksLoading,
    error: worksError,
    data: worksData
  } = useQuery(INGEST_SHEET_WORKS, {
    variables: { id: sheetId }
  });
  const {
    loading: errorsLoading,
    error: errorsError,
    data: errorsData
  } = useQuery(INGEST_SHEET_COMPLETED_ERRORS, { variables: { id: sheetId } });

  if (worksLoading || errorsLoading) return "Loading...";
  if (worksError) return <Error error={worksError.message} />;
  if (errorsError) return <Error error={errorsError.message} />;

  const works = worksData.ingestSheetWorks;
  let ingestSheetErrors = [];
  console.log("errorsData :", errorsData);
  try {
    ingestSheetErrors = errorsData.ingestSheetErrors;
  } catch (e) {}

  return (
    <>
      {ingestSheetErrors.length > 0 && (
        <section className="section">
          <IngestSheetCompletedErrors errors={ingestSheetErrors} />
        </section>
      )}

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
