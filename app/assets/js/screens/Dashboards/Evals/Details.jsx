import React, { useState } from "react";
import { useParams, Link } from "react-router-dom";
import { useQuery, useMutation } from "@apollo/client";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import ScoreButtons from "@js/components/Dashboards/Evals/ScoreButtons";
import TrialComparison from "@js/components/Dashboards/Evals/TrialComparison";
import {
  GET_EVAL_RUN,
  CANCEL_EVAL_RUN,
} from "@js/components/Dashboards/Evals/evals.gql";

const STATUS_COLORS = {
  PENDING: "is-warning",
  RUNNING: "is-info",
  COMPLETE: "is-success",
  ERRORED: "is-danger",
  CANCELLED: "is-light",
  SKIPPED: "is-light",
};

function percent(n) {
  if (n == null) return "—";
  return `${(n * 100).toFixed(1)}%`;
}

function scoreColor(_n) {
  return "";
}

function enumKey(value) {
  return value?.toString().toUpperCase();
}

function enumLabel(value) {
  return value?.toString().toLowerCase() || "";
}

export default function EvalsDetailsScreen() {
  const { id } = useParams();
  const [expandedTrialId, setExpandedTrialId] = useState(null);
  const [showPrompt, setShowPrompt] = useState(false);

  const { data, loading } = useQuery(GET_EVAL_RUN, {
    variables: { id },
    pollInterval: 5000,
  });

  const [cancelRun, { loading: cancelling }] = useMutation(CANCEL_EVAL_RUN, {
    refetchQueries: [{ query: GET_EVAL_RUN, variables: { id } }],
  });

  const run = data?.evalRun;
  const s = run?.summary || {};
  const trials = run?.evalTrials || [];
  const memberMap = Object.fromEntries(
    (run?.evalSet?.evalSetMembers || []).map((m) => [m.workId, m]),
  );

  const handleDownloadCsv = () => {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = `/api/evals/${encodeURIComponent(`eval_run_${id}.csv`)}`;
    const input = document.createElement("input");
    input.type = "hidden";
    input.name = "run_id";
    input.value = id;
    form.appendChild(input);
    document.body.appendChild(form);
    form.submit();
    document.body.removeChild(form);
  };

  if (loading) return <progress className="progress is-small is-primary" />;
  if (!run) return <div className="notification is-danger">Run not found.</div>;

  const runStatus = enumKey(run.status);
  const isActive = runStatus === "RUNNING" || runStatus === "PENDING";

  return (
    <Layout>
      <section className="section" data-testid="evals-detail-screen">
        <div className="container">
          <Breadcrumbs
            items={[
              { label: "Dashboards", isActive: false },
              {
                label: "AI Metadata Evals",
                route: "/dashboards/evals",
                isActive: false,
              },
              {
                label: run.name || run.evalSet?.name || id.slice(0, 8),
                route: `/dashboards/evals/runs/${id}`,
                isActive: true,
              },
            ]}
          />

          {/* Run header */}
          <div className="level">
            <div className="level-left">
              <div>
                <h1 className="title is-4">
                  {run.name || run.evalSet?.name}
                  <span
                    className={`tag ml-3 ${STATUS_COLORS[runStatus] || "is-light"}`}
                  >
                    {enumLabel(run.status)}
                  </span>
                </h1>
                <p className="subtitle is-6 has-text-grey">
                  Prompt:{" "}
                  <button
                    className="button is-ghost is-small p-0"
                    style={{ verticalAlign: "baseline", height: "auto", fontWeight: "normal", color: "inherit" }}
                    onClick={() => setShowPrompt((s) => !s)}
                  >
                    {run.promptVersion?.name}
                    <span className="ml-1" style={{ fontSize: "0.7rem" }}>{showPrompt ? "▴" : "▾"}</span>
                  </button>
                </p>
              </div>
            </div>
            <div className="level-right">
              <div className="level-item buttons">
                {isActive && (
                  <button
                    className={`button is-danger is-outlined${cancelling ? " is-loading" : ""}`}
                    onClick={() => cancelRun({ variables: { id } })}
                  >
                    Cancel Run
                  </button>
                )}
                <button className="button is-light" onClick={handleDownloadCsv}>
                  Download CSV
                </button>
              </div>
            </div>
          </div>

          {/* Prompt content (collapsible) */}
          {showPrompt && run.promptVersion && (
            <div className="box mb-4 is-size-7" style={{ background: "#fafafa" }}>
              <p className="label is-small">Subject headings task</p>
              <pre style={{ whiteSpace: "pre-wrap", background: "#f0f0f0", padding: "0.75rem", borderRadius: "4px", marginBottom: "1rem", fontSize: "0.75rem" }}>
                {run.promptVersion.subjectPrompt || "(none)"}
              </pre>
              <p className="label is-small">Description task</p>
              <pre style={{ whiteSpace: "pre-wrap", background: "#f0f0f0", padding: "0.75rem", borderRadius: "4px", fontSize: "0.75rem" }}>
                {run.promptVersion.descriptionPrompt || "(none)"}
              </pre>
            </div>
          )}

          {/* Summary stats */}
          <div className="columns mb-4">
            <div className="column is-narrow">
              <div className="box has-text-centered" style={{ borderTop: "3px solid #48c78e" }}>
                <p className="heading">Manual scoring</p>
                <p className="title is-3">
                  <span className="has-text-success">{s.manualGood ?? 0}</span>
                  {" / "}
                  <span className="has-text-danger">{s.manualBad ?? 0}</span>
                </p>
                <p className="is-size-7 has-text-grey">good / bad</p>
              </div>
            </div>
            <div className="column is-narrow">
              <div className="box has-text-centered">
                <p className="heading">Avg description score</p>
                <p className={`title is-3 ${scoreColor(s.meanDescriptionJudgeScore)}`}>
                  {percent(s.meanDescriptionJudgeScore)}
                </p>
                <p className="is-size-7 has-text-grey">LLM judge</p>
              </div>
            </div>
            <div className="column is-narrow">
              <div className="box has-text-centered">
                <p className="heading">Avg subjects score</p>
                <p className={`title is-3 ${scoreColor(s.meanSubjectsJudgeScore)}`}>
                  {percent(s.meanSubjectsJudgeScore)}
                </p>
                <p className="is-size-7 has-text-grey">LLM judge</p>
              </div>
            </div>
            <div className="column is-narrow">
              <div className="box has-text-centered">
                <p className="heading">Trials</p>
                <p className="title is-3">
                  {s.complete}/{s.total}
                </p>
                <p className="is-size-7 has-text-grey">{s.errored} errored</p>
              </div>
            </div>
          </div>

          {run.error && (
            <div className="notification is-danger is-light mb-4">
              <strong>Error:</strong> {run.error}
            </div>
          )}

          {/* Trials table */}
          <div className="table-container">
            <table className="table is-striped is-hoverable is-fullwidth is-size-7">
              <thead>
                <tr>
                  <th style={{ width: "1.5rem" }}></th>
                  <th>Work / Accession</th>
                  <th>#</th>
                  <th>Status</th>
                  <th>Desc score</th>
                  <th>Subj score</th>
                  <th>Manual Score</th>
                  <th>Scored By</th>
                </tr>
              </thead>
              <tbody>
                {trials.map((trial) => {
                  const member = memberMap[trial.workId] || {};
                  const trialStatus = enumKey(trial.status);
                  const isExpanded = expandedTrialId === trial.id;
                  const toggleExpand = () =>
                    setExpandedTrialId(isExpanded ? null : trial.id);
                  return (
                    <React.Fragment key={trial.id}>
                      <tr style={{ cursor: "pointer" }} onClick={toggleExpand}>
                        <td style={{ verticalAlign: "middle" }}>
                          <span style={{ fontSize: "0.75rem" }}>
                            {isExpanded ? "▾" : "▸"}
                          </span>
                        </td>
                        <td>
                          <div>
                            {member.accessionNumber || trial.workId?.slice(0, 8)}
                          </div>
                        </td>
                        <td>{trial.trialIndex + 1}</td>
                        <td>
                          <span
                            className={`tag ${STATUS_COLORS[trialStatus] || "is-light"}`}
                          >
                            {enumLabel(trial.status)}
                          </span>
                        </td>
                        <td className={scoreColor(trial.descriptionJudgeScore)}>
                          {percent(trial.descriptionJudgeScore)}
                        </td>
                        <td className={scoreColor(trial.subjectsJudgeScore)}>
                          {percent(trial.subjectsJudgeScore)}
                        </td>
                        <td onClick={(e) => e.stopPropagation()}>
                          {trialStatus === "COMPLETE" && (
                            <ScoreButtons trial={trial} runId={id} />
                          )}
                        </td>
                        <td className="is-size-7 has-text-grey">
                          {trial.manualScoredBy || "—"}
                        </td>
                      </tr>
                      {isExpanded && (
                        <tr>
                          <td
                            colSpan={8}
                            style={{ background: "#fafafa", borderTop: "none" }}
                          >
                            {trialStatus === "COMPLETE" ? (
                              <TrialComparison
                                groundTruth={member.groundTruth}
                                agentOutput={trial.agentOutput}
                                judgeRationale={trial.judgeRationale}
                              />
                            ) : (
                              <p className="has-text-grey is-size-7" style={{ padding: "1rem 0" }}>
                                {enumLabel(trial.status)} — no output yet
                              </p>
                            )}
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </Layout>
  );
}
