import React, { useEffect } from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetValidations from "./Validations";
import { GET_INGEST_SHEET_PROGRESS } from "./ingestSheet.query";
import IngestSheetAlert from "./Alert";
import PropTypes from "prop-types";
import IngestSheetActionRow from "./ActionRow";
import IngestSheetApprovedInProgress from "./ApprovedInProgress";
import IngestSheetCompleted from "./Completed";
import UIButton from "../UI/Button";
import DownloadIcon from "../../../css/fonts/zondicons/download.svg";

/**
 * Note: This component is dependent on the GraphQL "IngestSheet" data type "status" property.
 * Refer to latest values to clarify this component's logic.
 */

const IngestSheet = ({
  ingestSheetData,
  projectId,
  subscribeToIngestSheetUpdates
}) => {
  const { id, status } = ingestSheetData;

  const {
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore
  } = useQuery(GET_INGEST_SHEET_PROGRESS, {
    variables: { ingestSheetId: id },
    fetchPolicy: "network-only"
  });

  useEffect(() => {
    subscribeToIngestSheetUpdates();
  }, []);

  if (progressLoading) return <Loading />;
  if (progressError) return <Error error={progressError} />;

  const handleDownloadCsv = () => {
    //TODO: Put code to download CSV file here.
    // ie. hitSomeEndpoint(id)
    console.log("Put code to download CSV file here");
  };

  return (
    <>
      <IngestSheetAlert ingestSheet={ingestSheetData} />

      {["APPROVED"].indexOf(status) > -1 && (
        <IngestSheetApprovedInProgress ingestSheet={ingestSheetData} />
      )}

      {["COMPLETED"].indexOf(status) > -1 && (
        <>
          <UIButton classes="mt-6" onClick={handleDownloadCsv}>
            <DownloadIcon className="icon"></DownloadIcon> Download .csv
          </UIButton>
          <IngestSheetCompleted ingestSheetId={ingestSheetData.id} />
        </>
      )}

      {["VALID", "ROW_FAIL", "FILE_FAIL", "UPLOADED"].indexOf(status) > -1 && (
        <>
          <IngestSheetActionRow
            ingestSheetId={id}
            projectId={projectId}
            status={status}
          />
          <IngestSheetValidations
            ingestSheetId={id}
            status={status}
            initialProgress={progressData.ingestSheetProgress}
            subscribeToIngestSheetProgress={progressSubscribeToMore}
          />
        </>
      )}
    </>
  );
};

IngestSheet.propTypes = {
  ingestSheetData: PropTypes.object,
  projectId: PropTypes.string,
  subscribeToIngestSheetUpdates: PropTypes.func
};

export default IngestSheet;
