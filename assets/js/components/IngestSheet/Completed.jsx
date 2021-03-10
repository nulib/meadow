import React from "react";
import { useHistory } from "react-router-dom";
import { useQuery } from "@apollo/client";
import PropTypes from "prop-types";
import {
  INGEST_SHEET_WORKS,
  INGEST_SHEET_COMPLETED_ERRORS,
  INGEST_SHEET_WORK_COUNT,
} from "./ingestSheet.gql";
import Error from "../UI/Error";
import IngestSheetCompletedErrors from "./Completed/Errors";
import UIPreviewItems from "../UI/PreviewItems";
import UISkeleton from "../UI/Skeleton";
import { Button } from "@nulib/admin-react-components";
import IconImages from "@js/components/Icon/Images";
import UILevelItem from "@js/components/UI/LevelItem";

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
  const {
    loading: workCountLoading,
    error: workCountError,
    data: workCountData,
  } = useQuery(INGEST_SHEET_WORK_COUNT, {
    variables: { id: sheetId },
  });

  if (worksLoading || errorsLoading || workCountLoading)
    return <UISkeleton rows={10} />;
  if (worksError) return <Error error={worksError} />;
  if (errorsError) return <Error error={errorsError} />;
  if (workCountError) return <Error error={workCountError} />;

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
    <div>
      {ingestSheetErrors.length === 0 && (
        // <IngestSheetDetails totalWorks={workCountData.ingestSheetWorkCount} />
        <div className="level">
          <UILevelItem
            heading="Total Works"
            content={workCountData.ingestSheetWorkCount}
          />
        </div>
      )}

      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}

      {ingestSheetErrors.length === 0 && (
        <>
          <hr />
          <div className="is-flex is-justify-content-space-between mb-6 content">
            <h3>Preview of ingest sheet works...</h3>
            <Button isPrimary onClick={handleClick}>
              <span className="icon">
                <IconImages />
              </span>
              <span>View ingest sheet works</span>
            </Button>
          </div>
          <div data-testid="preview-wrapper">
            {errorsLoading || worksLoading ? (
              <UISkeleton rows={5} />
            ) : (
              <div>
                <UIPreviewItems items={works} />
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
};

IngestSheetCompleted.propTypes = {
  sheetId: PropTypes.string,
  title: PropTypes.string,
};

export default IngestSheetCompleted;
