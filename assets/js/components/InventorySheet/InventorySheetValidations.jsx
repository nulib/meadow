import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/react-hooks";
import { Line as ProgressBar } from 'rc-progress';
import debounce from 'lodash.debounce';
import InventorySheetReport from "./InventorySheetReport";
import {
  SUBSCRIBE_TO_INVENTORY_SHEET_STATUS,
  SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS,
  START_VALIDATION
} from "./inventorySheet.query";

function InventorySheetValidations({
  inventorySheetId,
  initialProgress,
  initialStatus,
  subscribeToInventorySheetProgress,
  subscribeToInventorySheetStatus
}) {
  const [progress, setProgress] = useState({states: []});
  const [status, setStatus] = useState([])
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);

  useEffect(() => {
    setProgress(initialProgress);
    subscribeToInventorySheetProgress({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS,
      variables: { inventorySheetId },
      updateQuery: debounce(handleProgressUpdate, 250, {maxWait: 250})
    });

    setStatus(initialStatus);
    subscribeToInventorySheetStatus({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_STATUS,
      variables: { inventorySheetId },
      updateQuery: handleStatusUpdate
    });

    startValidation({ variables: { id: inventorySheetId } });
  }, []);

  const handleProgressUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const progress = subscriptionData.data.ingestJobProgressUpdate;
    setProgress(progress);
    return { ingestJobProgress: progress };
  };

  const handleStatusUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const status = subscriptionData.data.ingestJobUpdate.state;
    setStatus(status);
    return { ingestJob: subscriptionData.data.ingestJobUpdate }
  };

  const isFinished = () => { 
    return status.find(({name, state}) => name == "overall" && state != "PENDING") 
  }

  const progressBar = () => {
    return (
      <>
        <ProgressBar 
          percent={progress.percentComplete}
          strokeWidth="4"
          trailWidth="4"
          strokeLinecap="square"
        />
        <p>Checks: {status.map(({name, state}) => `${name}: ${state} `)}</p>
        <p>Rows: {progress.states.map(({state, count}) => `${state}: ${count} `)}</p>
      </>
    );
  }

  const report = () => {
    if (isFinished()) {
      return (
        <>
          <InventorySheetReport
            progress={progress}
            jobState={status}
            inventorySheetId={inventorySheetId}
          />
        </>
      )
    } else {
      return(<></>)
    }
  }

  return (
    <>
      {progressBar()}
      {report()}
    </>
  )
}

InventorySheetValidations.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  initialProgress: PropTypes.object.isRequired,
  initialStatus: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default InventorySheetValidations;
