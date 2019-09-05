import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/react-hooks";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import InventorySheetReport from "./InventorySheetReport";
import {
  SUBSCRIBE_TO_INVENTORY_SHEET_STATUS,
  SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS,
  START_VALIDATION
} from "./inventorySheet.query";
import UIAlert from "../UI/Alert";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";
import CloseIcon from "../../../css/fonts/zondicons/close.svg";
import CheckMarkIcon from "../../../css/fonts/zondicons/checkmark.svg";

function InventorySheetValidations({
  inventorySheetId,
  initialProgress,
  initialStatus,
  subscribeToInventorySheetProgress,
  subscribeToInventorySheetStatus
}) {
  const [progress, setProgress] = useState({ states: [] });
  const [status, setStatus] = useState([]);
  const [displayRowChecks, setDisplayRowChecks] = useState(false);
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);

  useEffect(() => {
    setProgress(initialProgress);
    subscribeToInventorySheetProgress({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS,
      variables: { inventorySheetId },
      updateQuery: debounce(handleProgressUpdate, 250, { maxWait: 250 })
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
    return { ingestJob: subscriptionData.data.ingestJobUpdate };
  };

  const isFinished = () => {
    return status.find(
      ({ name, state }) => name == "overall" && state != "PENDING"
    );
  };

  const isFinishedAndErrors = () => {
    return (
      isFinished() &&
      status.find(({ name, state }) => name === "overall" && state === "FAIL")
    );
  };

  const progressBar = () => {
    return <UIProgressBar percentComplete={progress.percentComplete} />;
  };

  const alert = () => {
    if (isFinished()) {
      const failedChecks = status.filter(
        statusObj => statusObj.state === "FAIL"
      );

      if (failedChecks.length > 0) {
        const AlertBody = (
          <>
            {failedChecks.map(obj => (
              <p key={obj.name}>
                {obj.name}: {obj.state}
              </p>
            ))}
          </>
        );

        return (
          <UIAlert
            type="danger"
            title="The following Inventory Sheet validations failed:"
            body={AlertBody}
          />
        );
      }
      return (
        <UIAlert
          type="success"
          title="Validation success"
          body="All checks on the inventory sheet were successful"
        />
      );
    }
    return null;
  };

  const checks = () => (
    <div className="mb-4 pt-4">
      <button onClick={() => setDisplayRowChecks(!displayRowChecks)}>
        {displayRowChecks ? "Hide" : "Show"} row check details
      </button>

      {displayRowChecks && (
        <>
          <h2>Row checks</h2>
          <table className="mb-4">
            <thead>
              <tr>
                {status.map(({ name }) => (
                  <th key={name}>{name}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr>
                {status.map(({ state, name }) => (
                  <td
                    key={name}
                    className={`${
                      state === "PASS" ? "bg-green-400" : "bg-red-400"
                    } text-white`}
                  >
                    {name !== "rows"
                      ? state
                      : progress.states.map(
                          ({ state, count }) => `${state} (${count}) `
                        )}
                  </td>
                ))}
              </tr>
            </tbody>
          </table>
        </>
      )}
    </div>
  );

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
      );
    } else {
      return <></>;
    }
  };

  const userButtons = () => {
    if (isFinishedAndErrors()) {
      return (
        <ButtonGroup>
          <UIButton>
            <CloseIcon className="icon" />
            Delete job and re-upload inventory sheet
          </UIButton>
        </ButtonGroup>
      );
    }
    if (isFinished()) {
      return (
        <ButtonGroup>
          <UIButton>
            <CheckMarkIcon className="icon" />
            Approve inventory sheet
          </UIButton>
          <UIButton classes="btn-clear">
            <CloseIcon className="icon" />
            Delete job and re-upload inventory sheet
          </UIButton>
        </ButtonGroup>
      );
    }
  };

  return (
    <>
      {progressBar()}
      {alert()}
      {checks()}
      {report()}
      {userButtons()}
    </>
  );
}

InventorySheetValidations.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  initialProgress: PropTypes.object.isRequired,
  initialStatus: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default InventorySheetValidations;
