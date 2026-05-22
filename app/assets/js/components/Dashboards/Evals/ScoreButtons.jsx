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

  const score = (value) => {
    scoreTrialMutation({ variables: { id: trial.id, score: value } });
  };

  const clear = () => {
    clearScoreMutation({ variables: { id: trial.id } });
  };

  return (
    <div className="buttons are-small">
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
      {manualScore && manualScore !== "UNSCORED" && (
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
  );
}

ScoreButtons.propTypes = {
  trial: PropTypes.shape({
    id: PropTypes.string.isRequired,
    manualScore: PropTypes.string,
  }).isRequired,
  runId: PropTypes.string.isRequired,
};
