import React from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faNoteSticky } from "@fortawesome/free-solid-svg-icons";
import {
  SCORE_EVAL_TRIAL,
  CLEAR_EVAL_TRIAL_SCORE,
  GET_EVAL_RUN,
} from "./evals.gql";

export default function ScoreButtons({ trial, runId }) {
  const [scoreTrialMutation, { loading: scoring }] = useMutation(
    SCORE_EVAL_TRIAL,
    {
      refetchQueries: [{ query: GET_EVAL_RUN, variables: { id: runId } }],
    },
  );

  const [clearScoreMutation, { loading: clearing }] = useMutation(
    CLEAR_EVAL_TRIAL_SCORE,
    {
      refetchQueries: [{ query: GET_EVAL_RUN, variables: { id: runId } }],
    },
  );

  const isLoading = scoring || clearing;
  const manualScore = trial.manualScore?.toUpperCase();

  // Local note state, seeded from the current user's saved note.
  const [notes, setNotes] = React.useState(trial.manualNotes || "");
  const [noteOpen, setNoteOpen] = React.useState(false);
  React.useEffect(() => {
    setNotes(trial.manualNotes || "");
  }, [trial.manualNotes]);

  const hasNote = Boolean((notes || "").trim());

  const score = (value) => {
    scoreTrialMutation({
      variables: { id: trial.id, score: value, notes: notes || null },
    });
  };

  const saveNote = () => {
    // Persist the note against the existing good/bad score, then collapse
    // back to the read-only note + "Edit Note" view.
    if (manualScore === "GOOD" || manualScore === "BAD") {
      scoreTrialMutation({
        variables: { id: trial.id, score: manualScore, notes: notes || null },
        onCompleted: () => setNoteOpen(false),
      });
    }
  };

  const cancelNote = () => {
    // Discard any unsaved edits and collapse back to the read-only view.
    setNotes(trial.manualNotes || "");
    setNoteOpen(false);
  };

  const clear = () => {
    setNotes("");
    setNoteOpen(false);
    clearScoreMutation({ variables: { id: trial.id } });
  };

  const scored = manualScore && manualScore !== "UNSCORED";
  const noteDirty = (notes || "") !== (trial.manualNotes || "");

  return (
    <div>
      <div className="buttons are-small mb-1">
        <button
          className={`button is-success${manualScore === "GOOD" ? "" : " is-outlined"}`}
          disabled={isLoading}
          onClick={() => score("GOOD")}
          title="Mark as good"
        >
          Good
        </button>
        <button
          className={`button is-danger${manualScore === "BAD" ? "" : " is-outlined"}`}
          disabled={isLoading}
          onClick={() => score("BAD")}
          title="Mark as bad"
        >
          Bad
        </button>
        {scored && (
          <button
            className="button is-light"
            disabled={isLoading}
            onClick={clear}
            title="Clear score"
          >
            Clear
          </button>
        )}
      </div>
      {noteOpen ? (
        <>
          <textarea
            className="textarea is-small"
            rows={5}
            placeholder="Add a note (optional)"
            value={notes}
            disabled={isLoading}
            autoFocus
            onChange={(e) => setNotes(e.target.value)}
            onClick={(e) => e.stopPropagation()}
            style={{ minWidth: "14rem", fontSize: "0.75rem" }}
          />
          <div className="buttons are-small mt-1">
            {scored && noteDirty && (
              <button
                className="button is-link is-outlined"
                disabled={isLoading}
                onClick={saveNote}
                title="Save note"
              >
                Save note
              </button>
            )}
            <button
              className="button is-light"
              disabled={isLoading}
              onClick={cancelNote}
              title="Cancel"
            >
              Cancel
            </button>
          </div>
        </>
      ) : (
        <div style={{ maxWidth: "16rem" }}>
          {hasNote && (
            <p
              className="is-size-7 has-text-grey-dark mb-1"
              style={{ whiteSpace: "pre-wrap", wordBreak: "break-word" }}
            >
              {notes}
            </p>
          )}
          <button
            className="button is-text is-small px-1"
            disabled={isLoading}
            onClick={(e) => {
              e.stopPropagation();
              setNoteOpen(true);
            }}
            title={hasNote ? "Edit note" : "Add note"}
          >
            <span className="icon is-small">
              <FontAwesomeIcon icon={faNoteSticky} />
            </span>
            <span>{hasNote ? "Edit Note" : "Add Note"}</span>
          </button>
        </div>
      )}
    </div>
  );
}

ScoreButtons.propTypes = {
  trial: PropTypes.shape({
    id: PropTypes.string.isRequired,
    manualScore: PropTypes.string,
    manualNotes: PropTypes.string,
  }).isRequired,
  runId: PropTypes.string.isRequired,
};
