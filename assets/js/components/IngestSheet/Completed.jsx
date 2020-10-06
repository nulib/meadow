import React, { useState } from "react";
import { useQuery } from "@apollo/client";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS,
} from "./ingestSheet.gql";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import PreviewItems from "../BatchEdit/PreviewItems";
import UISkeleton from "../UI/Skeleton";
import UIFacetLink from "../UI/FacetLink";

const IngestSheetCompleted = ({ sheetId, title }) => {
  const {
    loading: worksLoading,
    error: worksError,
    data: worksData,
  } = useQuery(INGEST_SHEET_WORKS, {
    variables: { id: sheetId, limit: 10 },
    fetchPolicy: "network-only",
  });
  const {
    loading: errorsLoading,
    error: errorsError,
    data: errorsData,
  } = useQuery(INGEST_SHEET_COMPLETED_ERRORS, { variables: { id: sheetId } });

  if (worksLoading || errorsLoading) return <UISkeleton rows={10} />;
  if (worksError) return <Error error={worksError} />;
  if (errorsError) return <Error error={errorsError} />;

  const works = worksData.ingestSheetWorks;
  const facetItem = { term: { label: title } };

  let ingestSheetErrors = [];

  try {
    ingestSheetErrors = errorsData.ingestSheetErrors;
  } catch (e) {}

  return (
    <>
      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}

      <h2 className="title is-size-5 is-size-8">
        Ingest Sheet Content Preview
      </h2>

      <div data-testid="preview-wrapper">
        {errorsLoading || worksLoading ? (
          <UISkeleton rows={5} />
        ) : (
          <div>
            <PreviewItems items={works} />
            <p className="notification has-text-centered">
              This is a preview of Ingest Sheet works. To view full list of
              works in this Ingest Sheet click here <br />
              <UIFacetLink facetComponentId="IngestSheet" item={facetItem} />
            </p>
          </div>
        )}
      </div>
    </>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string,
  title: PropTypes.string,
};

export default IngestSheetCompleted;
