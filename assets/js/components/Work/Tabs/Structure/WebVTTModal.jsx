import React from "react";
import PropTypes from "prop-types";
import { Button, Notification } from "@nulib/admin-react-components";
import classNames from "classnames";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
const webvtt = require("node-webvtt");
import { GET_WORK, UPDATE_FILE_SET } from "@js/components/Work/work.gql";
import { toastWrapper } from "@js/services/helpers";
import { useMutation } from "@apollo/client";
import { useParams } from "react-router-dom";

function WorkTabsStructureWebVTTModal({ isActive }) {
  const dispatch = useWorkDispatch();
  const textAreaRef = React.useRef();
  const [parseErrors, setParseErrors] = React.useState();
  const workState = useWorkState();
  const [webVttValue, setWebVttValue] = React.useState("");
  const params = useParams();
  const workId = params.id;

  React.useEffect(() => {
    setWebVttValue(workState.webVttModal.webVttString);
  }, [workState.webVttModal.webVttString]);

  const [updateFileSet] = useMutation(UPDATE_FILE_SET, {
    onCompleted({ updateFileSet }) {
      toastWrapper("is-success", "webVTT structure successfully updated");
      handleClose();
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      let errorStrings = [];
      if (graphQLErrors?.length > 0) {
        errorStrings = graphQLErrors.map(
          ({ message, details }) =>
            `${message}: ${details && details.title ? details.title : ""}`
        );
      }
      toastWrapper("is-danger", errorStrings.join(" \n "));
    },
    refetchQueries: [
      {
        query: GET_WORK,
        variables: {
          id: workId,
        },
      },
    ],
  });

  const handleChange = (e) => {
    setWebVttValue(e.target.value);
    try {
      const parsed = webvtt.parse(e.target.value);
      if (parsed.valid) {
        setParseErrors(null);
      }
    } catch (e) {
      setParseErrors(e);
    }
  };

  const handleClose = () => {
    dispatch({ type: "toggleWebVttModal", fileSetId: null });
    setParseErrors(null);
    setWebVttValue("");
  };

  const handleSubmit = () => {
    updateFileSet({
      variables: {
        id: workState.webVttModal.fileSetId,
        structuralMetadata: {
          type: "WEBVTT",
          value: webVttValue,
        },
      },
    });
  };

  return (
    <div
      className={classNames(["modal"], {
        "is-active": isActive,
      })}
    >
      <div className="modal-background"></div>
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Update webVTT structure</p>
          <button
            type="button"
            className="delete"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>

        <section className="modal-card-body">
          {webVttValue?.trim().length > 0 &&
            (parseErrors ? (
              <Notification isDanger>{parseErrors.message}</Notification>
            ) : (
              <Notification isSuccess>Web VTT is valid</Notification>
            ))}
          <textarea
            className="textarea"
            onChange={handleChange}
            placeholder="Enter Web VTT text here"
            ref={textAreaRef}
            rows="10"
            style={{ whiteSpace: "pre-wrap" }}
            value={webVttValue}
          />
        </section>
        <footer className="modal-card-foot buttons is-right">
          <Button onClick={handleClose}>Cancel</Button>
          <Button isPrimary onClick={handleSubmit} disabled={parseErrors}>
            Submit
          </Button>
        </footer>
      </div>
    </div>
  );
}

WorkTabsStructureWebVTTModal.propTypes = {
  isActive: PropTypes.bool,
};

export default WorkTabsStructureWebVTTModal;
