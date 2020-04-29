import React, { useState } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS,
} from "./ingestSheet.query";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import WorkListItem from "../Work/UIWorkListItem";
import WorkCardItem from "../Work/UIWorkCardItem";

const IngestSheetCompleted = ({ sheetId }) => {
  const [isListView, setIsListView] = useState(false);
  const {
    loading: worksLoading,
    error: worksError,
    data: worksData,
  } = useQuery(INGEST_SHEET_WORKS, {
    variables: { id: sheetId },
    fetchPolicy: "network-only",
  });
  const {
    loading: errorsLoading,
    error: errorsError,
    data: errorsData,
  } = useQuery(INGEST_SHEET_COMPLETED_ERRORS, { variables: { id: sheetId } });

  if (worksLoading || errorsLoading)
    return (
      <progress className="progress is-primary" max="100">
        30%
      </progress>
    );
  if (worksError) return <Error error={worksError.message} />;
  if (errorsError) return <Error error={errorsError.message} />;

  const works = worksData.ingestSheetWorks;
  let ingestSheetErrors = [];

  const handleWorksViewChange = () => {
    setIsListView(!isListView);
  };

  try {
    ingestSheetErrors = errorsData.ingestSheetErrors;
  } catch (e) {}

  return (
    <>
      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}
      <div className="field has-text-right is-hidden-touch">
        <input
          id="checkbox-switch-listitem-view"
          type="checkbox"
          className="switch"
          checked={isListView}
          onChange={(e) => handleWorksViewChange()}
        />
        <label htmlFor="checkbox-switch-listitem-view">List View</label>
      </div>
      {!isListView && (
        <div className="columns is-multiline">
          {works.map((work) => (
            <div
              key={work.id}
              className="column is-half-tablet is-one-quarter-desktop"
            >
              <WorkCardItem key={work.id} work={work} />
            </div>
          ))}
        </div>
      )}
      {isListView && (
        <div className="">
          {works.map((work) => (
            <div key={work.id}>
              <WorkListItem key={work.id} work={work} />
            </div>
          ))}
        </div>
      )}
    </>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string,
};

export default IngestSheetCompleted;
