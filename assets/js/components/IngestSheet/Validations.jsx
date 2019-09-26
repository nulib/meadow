import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import ReactRouterPropTypes from "react-router-prop-types";
import { useMutation } from "@apollo/react-hooks";
import UIProgressBar from "../UI/UIProgressBar";
import debounce from "lodash.debounce";
import IngestSheetReport from "./Report";
import {
  DELETE_INGEST_SHEET,
  SUBSCRIBE_TO_INGEST_SHEET_STATUS,
  SUBSCRIBE_TO_INGEST_SHEET_PROGRESS,
  START_VALIDATION
} from "./ingestSheet.query";
import UIAlert from "../UI/Alert";
import ButtonGroup from "../UI/ButtonGroup";
import UIButton from "../UI/Button";
import CheckMarkIcon from "../../../css/fonts/zondicons/checkmark.svg";
import UIModalDelete from "../UI/Modal/Delete";
import { withRouter } from "react-router-dom";
import { toast } from "react-toastify";

function IngestSheetValidations({
  ingestSheetId,
  initialProgress,
  initialStatus,
  match,
  history,
  subscribeToIngestSheetProgress,
  subscribeToIngestSheetStatus
}) {
  const [progress, setProgress] = useState({ states: [] });
  const [status, setStatus] = useState([]);
  const [displayRowChecks, setDisplayRowChecks] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);
  const [deleteIngestSheet, { data: deleteIngestSheetData }] = useMutation(
    DELETE_INGEST_SHEET,
    {
      onCompleted({ deleteIngestSheet }) {
        toast(`Ingest sheet deleted successfully`);
        history.push(`/project/${match.params.id}`);
      }
    }
  );

  useEffect(() => {
    setProgress(initialProgress);
    subscribeToIngestSheetProgress({
      document: SUBSCRIBE_TO_INGEST_SHEET_PROGRESS,
      variables: { ingestSheetId },
      updateQuery: debounce(handleProgressUpdate, 250, { maxWait: 250 })
    });

    setStatus(initialStatus);
    subscribeToIngestSheetStatus({
      document: SUBSCRIBE_TO_INGEST_SHEET_STATUS,
      variables: { ingestSheetId },
      updateQuery: handleStatusUpdate
    });

    startValidation({ variables: { id: ingestSheetId } });
  }, []);

  const handleDeleteClick = () => {
    deleteIngestSheet({ variables: { ingestSheetId: ingestSheetId } });
  };

  const onOpenModal = () => {
    setDeleteModalOpen(true);
  };

  const onCloseModal = () => {
    setDeleteModalOpen(false);
  };

  const handleProgressUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const progress = subscriptionData.data.ingestSheetProgressUpdate;
    setProgress(progress);
    return { ingestSheetProgress: progress };
  };

  const handleStatusUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const status = subscriptionData.data.ingestSheetUpdate.state;
    setStatus(status);
    return { ingestSheet: subscriptionData.data.ingestSheetUpdate };
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
            title="The following Ingest Sheet validations failed:"
            body={AlertBody}
          />
        );
      }
      return (
        <UIAlert
          type="success"
          title="Validation success"
          body="All checks on the ingest sheet were successful"
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
          <IngestSheetReport
            progress={progress}
            sheetState={status}
            ingestSheetId={ingestSheetId}
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
          <UIButton classes="btn-danger" onClick={onOpenModal}>
            Delete sheet and re-upload ingest sheet
          </UIButton>
        </ButtonGroup>
      );
    }
    if (isFinished()) {
      return (
        <ButtonGroup>
          <UIButton>
            <CheckMarkIcon className="icon" />
            Approve ingest sheet
          </UIButton>
          <UIButton classes="btn-clear" onClick={onOpenModal}>
            Delete sheet and re-upload ingest sheet
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

      <UIModalDelete
        isOpen={deleteModalOpen}
        handleClose={onCloseModal}
        handleConfirm={handleDeleteClick}
        thingToDeleteLabel={`Ingest Sheet`}
      />
    </>
  );
}

IngestSheetValidations.propTypes = {
  ingestSheetId: PropTypes.string.isRequired,
  initialProgress: PropTypes.object.isRequired,
  initialStatus: PropTypes.arrayOf(PropTypes.object).isRequired,
  match: ReactRouterPropTypes.match,
  history: ReactRouterPropTypes.history
};

export default withRouter(IngestSheetValidations);
