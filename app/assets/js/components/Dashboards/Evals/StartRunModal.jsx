import React, { useState } from "react";
import PropTypes from "prop-types";
import { useMutation, useQuery } from "@apollo/client";
import {
  GET_EVAL_SETS,
  GET_EVAL_PROMPT_VERSIONS,
  GET_DEFAULT_EVAL_QUERY,
  GET_EVAL_QUERY_LIST,
  CREATE_EVAL_SET,
  CREATE_EVAL_SET_FROM_WORK_IDS,
  CREATE_EVAL_RUN,
  GET_EVAL_RUNS,
} from "./evals.gql";

const MAX_WORK_IDS = 20;

function parseWorkIds(text) {
  return Array.from(
    new Set(
      text
        .split(/\r?\n/)
        .map((s) => s.trim())
        .filter(Boolean)
    )
  );
}

export default function StartRunModal({ onClose, onStarted }) {
  const [evalSetId, setEvalSetId] = useState("");
  const [promptVersionId, setPromptVersionId] = useState("");
  const [createSetName, setCreateSetName] = useState("");
  const [selectedQueryId, setSelectedQueryId] = useState("");
  const [workIdsText, setWorkIdsText] = useState("");
  const [mode, setMode] = useState("existing");

  const { data: setsData } = useQuery(GET_EVAL_SETS);
  const { data: promptsData } = useQuery(GET_EVAL_PROMPT_VERSIONS);
  const { data: queriesData } = useQuery(GET_EVAL_QUERY_LIST);
  const { data: defaultQueryData } = useQuery(GET_DEFAULT_EVAL_QUERY, {
    onCompleted: (d) => {
      if (d?.defaultEvalQuery) setSelectedQueryId(d.defaultEvalQuery.id);
    },
  });

  const [createSet, { loading: creatingSet }] = useMutation(CREATE_EVAL_SET, {
    refetchQueries: [{ query: GET_EVAL_SETS }],
  });

  const [createSetFromIds, { loading: creatingSetFromIds }] = useMutation(
    CREATE_EVAL_SET_FROM_WORK_IDS,
    { refetchQueries: [{ query: GET_EVAL_SETS }] }
  );

  const [createRun, { loading: creatingRun }] = useMutation(CREATE_EVAL_RUN, {
    refetchQueries: [{ query: GET_EVAL_RUNS }],
  });

  const sets = setsData?.evalSets || [];
  const prompts = promptsData?.evalPromptVersions || [];
  const latestPrompt = prompts[0];

  React.useEffect(() => {
    if (latestPrompt && !promptVersionId) setPromptVersionId(latestPrompt.id);
  }, [latestPrompt]);

  React.useEffect(() => {
    if (sets.length > 0 && !evalSetId) setEvalSetId(sets[0].id);
  }, [sets]);

  const parsedIds = parseWorkIds(workIdsText);
  const tooManyIds = parsedIds.length > MAX_WORK_IDS;

  const handleCreateSetAndRun = async () => {
    let setId = evalSetId;

    if (mode === "new") {
      const result = await createSet({
        variables: { queryId: selectedQueryId, name: createSetName || `Set ${new Date().toISOString()}` },
      });
      setId = result.data?.createEvalSet?.id;
    } else if (mode === "ids") {
      const result = await createSetFromIds({
        variables: {
          workIds: parsedIds,
          name: createSetName || `Set ${new Date().toISOString()}`,
        },
      });
      setId = result.data?.createEvalSetFromWorkIds?.id;
    }

    if (!setId) return;

    const result = await createRun({
      variables: {
        evalSetId: setId,
        promptVersionId,
        trialsPerWork: 1,
        concurrency: 3,
      },
    });

    if (result.data?.createEvalRun) {
      onStarted(result.data.createEvalRun.id);
    }
  };

  const isLoading = creatingSet || creatingSetFromIds || creatingRun;

  const canSubmit =
    !!promptVersionId &&
    !tooManyIds &&
    (mode === "existing"
      ? !!evalSetId
      : mode === "new"
        ? !!selectedQueryId
        : parsedIds.length >= 1);

  return (
    <div className="modal is-active">
      <div className="modal-background" onClick={onClose} />
      <div className="modal-card">
        <header className="modal-card-head">
          <p className="modal-card-title">Start New Eval Run</p>
          <button className="delete" onClick={onClose} />
        </header>

        <section className="modal-card-body">
          <div className="field">
            <label className="label">Eval Set</label>
            <div className="control">
              <div className="select" style={{ marginBottom: "0.5rem" }}>
                <select value={mode} onChange={(e) => setMode(e.target.value)}>
                  <option value="existing">Use existing set</option>
                  <option value="new">Create new set from query</option>
                  <option value="ids">Paste work IDs</option>
                </select>
              </div>
            </div>

            {mode === "existing" && (
              <div className="control">
                <div className="select is-fullwidth">
                  <select value={evalSetId} onChange={(e) => setEvalSetId(e.target.value)}>
                    {sets.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.workCount} works)
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            )}

            {mode === "new" && (
              <>
                <div className="control" style={{ marginBottom: "0.5rem" }}>
                  <input
                    className="input"
                    placeholder="New set name"
                    value={createSetName}
                    onChange={(e) => setCreateSetName(e.target.value)}
                  />
                </div>
                <div className="control">
                  <div className="select is-fullwidth">
                    <select value={selectedQueryId} onChange={(e) => setSelectedQueryId(e.target.value)}>
                      <option value="">Select a query…</option>
                      {(queriesData?.evalQueryList || []).map((q) => (
                        <option key={q.id} value={q.id}>
                          {q.name}{q.id === defaultQueryData?.defaultEvalQuery?.id ? " (default)" : ""}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </>
            )}

            {mode === "ids" && (
              <>
                <div className="control" style={{ marginBottom: "0.5rem" }}>
                  <input
                    className="input"
                    placeholder="New set name (optional)"
                    value={createSetName}
                    onChange={(e) => setCreateSetName(e.target.value)}
                  />
                </div>
                <div className="control">
                  <textarea
                    className={`textarea is-family-monospace is-size-7${tooManyIds ? " is-danger" : ""}`}
                    rows={6}
                    placeholder={"One work ID per line — up to 20"}
                    value={workIdsText}
                    onChange={(e) => setWorkIdsText(e.target.value)}
                  />
                </div>
                <p className={`help${tooManyIds ? " is-danger" : ""}`}>
                  {parsedIds.length === 0
                    ? `Max ${MAX_WORK_IDS} IDs`
                    : tooManyIds
                      ? `${parsedIds.length} IDs — trim to ${MAX_WORK_IDS} or fewer`
                      : `${parsedIds.length} ID${parsedIds.length !== 1 ? "s" : ""} (max ${MAX_WORK_IDS})`}
                </p>
              </>
            )}
          </div>

          <div className="field">
            <label className="label">Prompt Version</label>
            <div className="control">
              <div className="select is-fullwidth">
                <select value={promptVersionId} onChange={(e) => setPromptVersionId(e.target.value)}>
                  {prompts.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>
        </section>

        <footer className="modal-card-foot">
          <button
            className={`button is-primary${isLoading ? " is-loading" : ""}`}
            disabled={!canSubmit || isLoading}
            onClick={handleCreateSetAndRun}
          >
            Start Run
          </button>
          <button className="button" onClick={onClose}>
            Cancel
          </button>
        </footer>
      </div>
    </div>
  );
}

StartRunModal.propTypes = {
  onClose: PropTypes.func.isRequired,
  onStarted: PropTypes.func.isRequired,
};
