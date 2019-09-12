import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/react-hooks";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import InventorySheetReport from "./Report";
import {
  SUBSCRIBE_TO_INVENTORY_SHEET_STATUS,
  SUBSCRIBE_TO_INVENTORY_SHEET_PROGRESS,
  START_VALIDATION
} from "./inventorySheet.query";
import UIAlert from "../UI/Alert";
import ButtonGroup from "../UI/ButtonGroup";
import UIButton from "../UI/Button";
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

  const showProgressBar = () => {
    if (isFinished()) {
      return null;
    }
    return (
      <UIProgressBar
        percentComplete={progress.percentComplete}
        label="Please wait for validation"
      />
    );
  };

  const showAlert = () => {
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

  const showChecksTable = () => (
    <div className="mb-12 pt-8">
      <button
        className="btn btn-clear"
        onClick={() => setDisplayRowChecks(!displayRowChecks)}
      >
        {displayRowChecks ? "Hide" : "Show"} row check details
      </button>

      {displayRowChecks && (
        <>
          <table className="mt-4">
            <thead>
              <tr>
                {status.map(({ name }) => (
                  <th key={name}>{name}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              <tr>
                {status.map(({ state, name }) => {
                  let colorClass = "";

                  if (state === "PASS") {
                    colorClass = "bg-green-400";
                  } else if (state === "FAIL") {
                    colorClass = "bg-red-400";
                  }

                  return (
                    <td key={name} className={`${colorClass} text-white`}>
                      {name !== "rows"
                        ? state
                        : progress.states.map(
                            ({ state, count }) => `${state} (${count}) `
                          )}
                    </td>
                  );
                })}
              </tr>
            </tbody>
          </table>
        </>
      )}
    </div>
  );

  const showReport = () => {
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

  const showUserButtons = () => {
    if (isFinishedAndErrors()) {
      return (
        <ButtonGroup>
          <UIButton classes="btn-danger">
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
            Delete job and re-upload inventory sheet
          </UIButton>
        </ButtonGroup>
      );
    }
  };

  return (
    <>
      <section>
        <h2>Unapproved State UI</h2>
        {showProgressBar()}
        {showAlert()}
        {showChecksTable()}
        {showReport()}
        {showUserButtons()}
      </section>

      <section className="pt-12">
        <h2>Approved State UI</h2>
        <p>
          Guessing once the use hits approve, could the API expose an "approved"
          flag the front-end can reference?{" "}
        </p>
        <UIAlert
          type="success"
          body="Inventory sheet has been approved and skeleton works are being created"
          title="Inventory sheet approved"
        />
        <div className="pt-12">
          <UIProgressBar percentComplete={50} label="works being created" />
        </div>
        <div class="text-center leading-loose text-gray-600">
          <p>48 works are being created</p>
          <p>370 file sets are being created</p>
          <p>What other info goes here?</p>
        </div>
      </section>
    </>
  );
}

InventorySheetValidations.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  initialProgress: PropTypes.object.isRequired,
  initialStatus: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default InventorySheetValidations;
