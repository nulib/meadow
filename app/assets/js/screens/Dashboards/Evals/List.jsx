import React, { useState } from "react";
import { Link, useHistory } from "react-router-dom";
import { useQuery, useMutation } from "@apollo/client";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import UIModalDelete from "@js/components/UI/Modal/Delete";
import StartRunModal from "@js/components/Dashboards/Evals/StartRunModal";
import {
  GET_EVAL_RUNS,
  DELETE_EVAL_RUN,
} from "@js/components/Dashboards/Evals/evals.gql";

const STATUS_COLORS = {
  PENDING: "is-warning",
  RUNNING: "is-info",
  COMPLETE: "is-success",
  ERRORED: "is-danger",
  CANCELLED: "is-light",
};

const DELETABLE_STATUSES = ["COMPLETE", "ERRORED", "CANCELLED"];

function enumKey(value) {
  return value?.toString().toUpperCase();
}

function enumLabel(value) {
  return value?.toString().toLowerCase() || "";
}

export default function EvalsListScreen() {
  const history = useHistory();
  const [showModal, setShowModal] = useState(false);
  const [runToDelete, setRunToDelete] = useState(null);
  const { data, loading } = useQuery(GET_EVAL_RUNS, {
    variables: { limit: 50, offset: 0 },
    pollInterval: 5000,
  });

  const [deleteRun] = useMutation(DELETE_EVAL_RUN, {
    refetchQueries: [
      { query: GET_EVAL_RUNS, variables: { limit: 50, offset: 0 } },
    ],
  });

  const runs = data?.evalRuns || [];

  const handleStarted = (runId) => {
    setShowModal(false);
    history.push(`/dashboards/evals/runs/${runId}`);
  };

  const handleDeleteConfirm = async () => {
    if (runToDelete) await deleteRun({ variables: { id: runToDelete.id } });
    setRunToDelete(null);
  };

  return (
    <Layout>
      <section className="section" data-testid="evals-list-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              { label: "Dashboards", isActive: false },
              {
                label: "AI Metadata Evals",
                route: "/dashboards/evals",
                isActive: true,
              },
            ]}
          />

          <div className="level">
            <div className="level-left">
              <div className="level-item">
                <h1 className="title">AI Metadata Evals</h1>
              </div>
            </div>
            <div className="level-right">
              <div className="level-item">
                <AuthDisplayAuthorized level="EDITOR">
                  <Link
                    to="/dashboards/evals/prompts"
                    className="button is-light mr-2"
                  >
                    Prompt Versions
                  </Link>
                </AuthDisplayAuthorized>
                <AuthDisplayAuthorized level="SUPERUSER">
                  <Link
                    to="/dashboards/evals/queries"
                    className="button is-light mr-2"
                  >
                    Manage Queries
                  </Link>
                </AuthDisplayAuthorized>
                <AuthDisplayAuthorized level="EDITOR">
                  <button
                    className="button is-primary"
                    onClick={() => setShowModal(true)}
                  >
                    Start New Run
                  </button>
                </AuthDisplayAuthorized>
              </div>
            </div>
          </div>

          {loading && <progress className="progress is-small is-primary" />}

          {runs.length === 0 && !loading ? (
            <div className="notification is-light">
              No eval runs yet. Click &ldquo;Start New Run&rdquo; to begin.
            </div>
          ) : (
            <div className="table-container">
              <table className="table is-striped is-hoverable is-fullwidth">
                <thead>
                  <tr>
                    <th>Name / Set</th>
                    <th>Prompt</th>
                    <th>Status</th>
                    <th>Trials</th>
                    <th>Desc score</th>
                    <th>Subj score</th>
                    <th>Manual</th>
                    <th>Started</th>
                    <th></th>
                  </tr>
                </thead>
                <tbody>
                  {runs.map((run) => {
                    const s = run.summary || {};
                    const status = enumKey(run.status);
                    return (
                      <tr key={run.id}>
                        <td>
                          <Link to={`/dashboards/evals/runs/${run.id}`}>
                            {run.name ||
                              run.evalSet?.name ||
                              run.id.slice(0, 8)}
                          </Link>
                          {run.evalSet && (
                            <div className="is-size-7 has-text-grey">
                              {run.evalSet.name}
                            </div>
                          )}
                        </td>
                        <td className="is-size-7">{run.promptVersion?.name}</td>
                        <td>
                          <span
                            className={`tag ${STATUS_COLORS[status] || "is-light"}`}
                          >
                            {enumLabel(run.status)}
                          </span>
                        </td>
                        <td>
                          {s.complete ?? 0}/{s.total ?? 0}
                        </td>
                        <td className="is-size-7">
                          {s.meanDescriptionJudgeScore != null
                            ? `${(s.meanDescriptionJudgeScore * 100).toFixed(0)}%`
                            : "—"}
                        </td>
                        <td className="is-size-7">
                          {s.meanSubjectsJudgeScore != null
                            ? `${(s.meanSubjectsJudgeScore * 100).toFixed(0)}%`
                            : "—"}
                        </td>
                        <td className="is-size-7">
                          <span className="has-text-success">
                            {s.manualGood ?? 0}
                          </span>
                          {" / "}
                          <span className="has-text-danger">
                            {s.manualBad ?? 0}
                          </span>
                        </td>
                        <td className="is-size-7">
                          {run.startedAt
                            ? new Date(run.startedAt).toLocaleDateString()
                            : "—"}
                        </td>
                        <td>
                          <div className="buttons are-small">
                            <Link
                              to={`/dashboards/evals/runs/${run.id}`}
                              className="button is-small is-light"
                            >
                              View
                            </Link>
                            {DELETABLE_STATUSES.includes(status) && (
                              <AuthDisplayAuthorized level="EDITOR">
                                <button
                                  className="button is-small is-danger is-light"
                                  onClick={() => setRunToDelete(run)}
                                >
                                  Delete
                                </button>
                              </AuthDisplayAuthorized>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </section>

      {showModal && (
        <StartRunModal
          onClose={() => setShowModal(false)}
          onStarted={handleStarted}
        />
      )}

      <UIModalDelete
        isOpen={!!runToDelete}
        handleClose={() => setRunToDelete(null)}
        handleConfirm={handleDeleteConfirm}
        thingToDeleteLabel={
          runToDelete?.name || runToDelete?.evalSet?.name || "this eval run"
        }
      />
    </Layout>
  );
}
