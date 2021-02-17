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
import UIPreviewItems from "../UI/PreviewItems";
import UISkeleton from "../UI/Skeleton";
import { Button } from "@nulib/admin-react-components";
import IngestSheetDetails from "@js/components/IngestSheet/Details";
import { elasticsearchDirectSearch } from "@js/services/elasticsearch";

const IngestSheetCompleted = ({ sheetId, title }) => {
  const history = useHistory();
  const [totalWorks, setTotalWorks] = React.useState();
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

  React.useEffect(() => {
    const fn = async () => {
      const response = await elasticsearchDirectSearch({
        query: {
          bool: {
            must: [
              {
                match: {
                  "model.name.keyword": "Image",
                },
              },
              {
                match: {
                  "model.application": "Meadow",
                },
              },
              {
                match: {
                  "sheet.id": sheetId,
                },
              },
            ],
          },
        },
        size: 0,
      });
      setTotalWorks(response.hits.total);
    };
    fn();
  }, [sheetId]);

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
    <div>
      {ingestSheetErrors.length === 0 && (
        <IngestSheetDetails totalWorks={totalWorks} />
      )}

      {ingestSheetErrors.length > 0 && (
        <IngestSheetCompletedErrors errors={ingestSheetErrors} />
      )}

      {ingestSheetErrors.length === 0 && (
        <>
          <hr />
          <div className="is-flex is-justify-content-space-between is-align-items-center mb-4">
            <p>Preview of ingest sheet works...</p>
            <Button onClick={handleClick}>
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
