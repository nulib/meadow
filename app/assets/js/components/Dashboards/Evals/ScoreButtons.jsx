import React from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client";
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
  React.useEffect(() => {
    setNotes(trial.manualNotes || "");
  }, [trial.manualNotes]);

  const score = (value) => {
    scoreTrialMutation({
      variables: { id: trial.id, score: value, notes: notes || null },
    });
  };

  const saveNote = () => {
    // Persist the note against the existing good/bad score.
    if (manualScore === "GOOD" || manualScore === "BAD") {
      score(manualScore);
    }
  };

  const clear = () => {
    setNotes("");
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
      <textarea
        className="textarea is-small"
        rows={2}
        placeholder="Add a note (optional)"
        value={notes}
        disabled={isLoading}
        onChange={(e) => setNotes(e.target.value)}
        onClick={(e) => e.stopPropagation()}
        style={{ minWidth: "14rem", fontSize: "0.75rem" }}
      />
      {scored && noteDirty && (
        <button
          className="button is-link is-small is-outlined mt-1"
          disabled={isLoading}
          onClick={saveNote}
          title="Save note"
        >
          Save note
        </button>
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
