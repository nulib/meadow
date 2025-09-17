import React from "react";
import PropTypes from "prop-types";
import { Button, Notification } from "@nulib/design-system";
import classNames from "classnames";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
import { WebVTTParser } from "webvtt-parser";
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
  const [confirmDelete, setConfirmDelete] = React.useState(false);
  const params = useParams();
  const workId = params.id;

  const parser = new WebVTTParser();

  React.useEffect(() => {
    setWebVttValue(workState.webVttModal.webVttString);
  }, [workState.webVttModal.webVttString]);

  const [updateFileSet] = useMutation(UPDATE_FILE_SET, {
    onCompleted({ updateFileSet }) {
      toastWrapper("is-success", "WebVTT structure successfully updated");
      handleClose();
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      let errorStrings = [];
      if (graphQLErrors?.length > 0) {
        errorStrings = graphQLErrors.map(
          ({ message, details }) =>
            `${message}: ${details && details.title ? details.title : ""}`,
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

  const throwValidationErrors = (parsedErrors) => {
    if (!parsedErrors || parsedErrors.length === 0) return;

    const jsx = (
      <ol
        style={{
          margin: "1em 2em",
        }}
      >
        {parsedErrors.map((err, idx) => (
          <li key={idx}>
            Line {err.line}, column {err.column ?? err.col}: {err.message}
          </li>
        ))}
      </ol>
    );

    const error = new Error("Validation failed");
    error.jsx = jsx;
    throw error;
  };

  const handleChange = (e) => {
    setWebVttValue(e.target.value);

    try {
      const parsed = parser.parse(e.target.value, "vtt");
      if (!parsed.errors.length) {
        setParseErrors(null);
        return;
      }
      throwValidationErrors(parsed.errors);
    } catch (err) {
      setParseErrors(err.jsx || err.message);
    }
  };

  const handleClose = () => {
    dispatch({ type: "toggleWebVttModal", fileSetId: null });
    setParseErrors(null);
    setWebVttValue("");
    setConfirmDelete(false);
  };

  const handleSubmit = (structuralMetadata) => {
    updateFileSet({
      variables: {
        id: workState.webVttModal.fileSetId,
        structuralMetadata,
      },
    });
  };

  const handleDelete = () => {
    setConfirmDelete(true);
    setParseErrors("Are you sure you want to delete this WebVTT structure?");
    setWebVttValue("");
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
          <p className="modal-card-title">Update WebVTT structure</p>
          <button
            type="button"
            className="delete"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>

        <section className="modal-card-body">
          {confirmDelete && (
            <Notification isDanger>
              Are you sure you want to delete this WebVTT structure?
            </Notification>
          )}

          {webVttValue?.trim().length > 0 &&
            (parseErrors ? (
              <Notification isDanger>
                WebVTT is not valid: {parseErrors}
              </Notification>
            ) : (
              <Notification isSuccess>WebVTT is valid</Notification>
            ))}
          <textarea
            className="textarea"
            onChange={handleChange}
            placeholder="Enter WebVTT text here"
            ref={textAreaRef}
            rows="10"
            style={{
              whiteSpace: "pre-wrap",
              display: confirmDelete ? "none" : "block",
            }}
            value={webVttValue}
          />
        </section>
        <footer className="modal-card-foot buttons is-justify-content-space-between">
          {webVttValue?.trim().length > 0 && !confirmDelete && (
            <Button
              isText
              onClick={() => handleDelete()}
              css={{ backgroundColor: "transparent" }}
            >
              Delete WebVTT
            </Button>
          )}
          <div className="is-flex is-justify-content-flex-end is-flex-grow-1">
            <Button onClick={handleClose}>Cancel</Button>
            {confirmDelete ? (
              <Button isPrimary onClick={() => handleSubmit({})}>
                Yes, delete
              </Button>
            ) : (
              <Button
                isPrimary
                onClick={() =>
                  handleSubmit({
                    type: "WEBVTT",
                    value: webVttValue,
                  })
                }
                disabled={parseErrors}
              >
                Submit
              </Button>
            )}
          </div>
        </footer>
      </div>
    </div>
  );
}

WorkTabsStructureWebVTTModal.propTypes = {
  isActive: PropTypes.bool,
};

export default WorkTabsStructureWebVTTModal;
