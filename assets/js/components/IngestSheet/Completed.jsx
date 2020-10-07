import React from "react";
import { useHistory } from "react-router-dom";
import { useQuery } from "@apollo/client";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS,
} from "./ingestSheet.gql";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import PreviewItems from "../UI/PreviewItems";
import UISkeleton from "../UI/Skeleton";
import { Button } from "@nulib/admin-react-components";

const IngestSheetCompleted = ({ sheetId, title }) => {
  const history = useHistory();
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
  const handleClick = () => {
    history.push("/search", {
      externalFacet: {
        facetComponentId: "IngestSheet",
        value: title,
      },
    });
  };
  let ingestSheetErrors = [];

  try {
    ingestSheetErrors = errorsData.ingestSheetErrors;
  } catch (e) {}

  return (
    <>
      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}

      <h2 className="title is-size-5 is-size-8">Works Preview</h2>

      <div data-testid="preview-wrapper">
        {errorsLoading || worksLoading ? (
          <UISkeleton rows={5} />
        ) : (
          <div>
            <PreviewItems items={works} />

            <p className="pt-4 has-text-centered">
              This is a preview of Ingest Sheet works. To view full list of
              works in this Ingest Sheet click here <br />
              <Button isPrimary className="mt-4" onClick={handleClick}>
                View All Ingest Sheet Works
              </Button>
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
