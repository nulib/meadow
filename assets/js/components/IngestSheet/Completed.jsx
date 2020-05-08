import React, { useState } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS,
} from "./ingestSheet.query";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
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
  if (worksError) return <Error error={worksError} />;
  if (errorsError) return <Error error={errorsError} />;

  const works = worksData.ingestSheetWorks;
  let ingestSheetErrors = [];

  const getWorkObject = (work) => {
    // Destructuring work here involves assigning a const to each
    // field and returning all constants. Tried various mappings to assign
    // destructured props to new obj and return with single liner
    // but nothing good with DRY kind of code.
    return {
      id: work.id,
      representativeImage: work.representativeImage,
      title: work.descriptiveMetadata.title,
      workType: work.workType,
      visibility: work.visibility,
      published: work.published,
      accessionNumber: work.accessionNumber,
      fileSets: work.fileSets.length,
      manifestUrl: work.manifestUrl,
      updatedAt: work.updatedAt,
    };
  };

  try {
    ingestSheetErrors = errorsData.ingestSheetErrors;
  } catch (e) {}

  return (
    <>
      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}

      <div className="columns">
        <div className="column is-half">
          <h2 className="title is-size-5 column is-size-8">
            Ingest Sheet Contents
          </h2>
        </div>
        <div className="column is-half is-hidden-touch">
          <div className="buttons is-right ">
            <button
              className="button is-text"
              onClick={() => setIsListView(false)}
              title="Grid View"
            >
              <span className={`icon ${isListView ? "has-text-grey" : ""}`}>
                <FontAwesomeIcon size="2x" icon="th-large" />
              </span>
            </button>

            <button
              className="button is-text"
              onClick={() => setIsListView(true)}
              title="List View"
            >
              <span className={`icon ${!isListView ? "has-text-grey" : ""}`}>
                <FontAwesomeIcon size="2x" icon="th-list" />
              </span>
            </button>
          </div>
        </div>
      </div>
      {!isListView && (
        <div className="columns is-multiline">
          {works.map((work) => (
            <div
              key={work.id}
              className="column is-half-tablet is-one-quarter-desktop"
            >
              <WorkCardItem key={work.id} {...getWorkObject(work)} />
            </div>
          ))}
        </div>
      )}
      {isListView && (
        <>
          {works.map((work) => (
            <div key={work.id} className="box">
              <WorkListItem key={work.id} {...getWorkObject(work)} />
            </div>
          ))}
        </>
      )}
    </>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string,
};

export default IngestSheetCompleted;
