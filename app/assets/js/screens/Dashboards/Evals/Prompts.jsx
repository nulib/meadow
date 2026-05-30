import React, { useState } from "react";
import { useQuery, useMutation } from "@apollo/client";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import {
  GET_EVAL_PROMPT_VERSIONS,
  CREATE_EVAL_PROMPT_VERSION,
  ARCHIVE_EVAL_PROMPT_VERSION,
} from "@js/components/Dashboards/Evals/evals.gql";

function PromptVersionCard({ v, isLatest, onArchive }) {
  const [showPrompts, setShowPrompts] = useState(false);
  return (
    <div className="box">
      <div className="level is-marginless">
        <div className="level-left">
          <div>
            <strong>{v.name}</strong>
            {isLatest && (
              <span className="tag is-success is-light ml-2">latest</span>
            )}
            {v.archived && <span className="tag is-light ml-2">archived</span>}
            {v.changeNotes && (
              <p className="is-size-7 has-text-grey">{v.changeNotes}</p>
            )}
            <p className="is-size-7 has-text-grey-light">
              by {v.author || "unknown"} ·{" "}
              {new Date(v.insertedAt).toLocaleDateString()}
            </p>
          </div>
        </div>
        <div className="level-right" style={{ gap: "0.5rem" }}>
          <button
            className="button is-small is-light"
            onClick={() => setShowPrompts((s) => !s)}
          >
            {showPrompts ? "Hide tasks" : "View tasks"}
          </button>
          {!v.archived && (
            <button
              className="button is-small is-light is-warning"
              onClick={onArchive}
            >
              Archive
            </button>
          )}
        </div>
      </div>
      {showPrompts && (
        <div className="mt-4">
          <p className="label is-small">Subject headings task</p>
          <pre
            className="is-size-7"
            style={{
              whiteSpace: "pre-wrap",
              background: "#f5f5f5",
              padding: "0.75rem",
              borderRadius: "4px",
              marginBottom: "1rem",
            }}
          >
            {v.subjectPrompt || "(none)"}
          </pre>
          <p className="label is-small">Description task</p>
          <pre
            className="is-size-7"
            style={{
              whiteSpace: "pre-wrap",
              background: "#f5f5f5",
              padding: "0.75rem",
              borderRadius: "4px",
            }}
          >
            {v.descriptionPrompt || "(none)"}
          </pre>
        </div>
      )}
    </div>
  );
}

export default function EvalsPromptsScreen() {
  const { data, loading } = useQuery(GET_EVAL_PROMPT_VERSIONS);
  const [showNew, setShowNew] = useState(false);
  const [form, setForm] = useState({
    name: "",
    subjectPrompt: "",
    descriptionPrompt: "",
    changeNotes: "",
  });

  const [createVersion] = useMutation(CREATE_EVAL_PROMPT_VERSION, {
    refetchQueries: [{ query: GET_EVAL_PROMPT_VERSIONS }],
  });
  const [archiveVersion] = useMutation(ARCHIVE_EVAL_PROMPT_VERSION, {
    refetchQueries: [{ query: GET_EVAL_PROMPT_VERSIONS }],
  });

  const versions = data?.evalPromptVersions || [];
  const latest = versions[0];
  const latestId = latest?.id;

  const resetForm = () => {
    setForm({
      name: "",
      subjectPrompt: latest?.subjectPrompt || "",
      descriptionPrompt: latest?.descriptionPrompt || "",
      changeNotes: "",
    });
  };

  const handleSave = async () => {
    await createVersion({
      variables: {
        ...form,
        parentVersionId: latestId,
      },
    });
    setShowNew(false);
    resetForm();
  };

  return (
    <Layout>
      <section className="section">
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
                label: "Prompt Versions",
                route: "/dashboards/evals/prompts",
                isActive: true,
              },
            ]}
          />

          <div className="level">
            <div className="level-left">
              <h1 className="title">Prompt Versions</h1>
            </div>
            <div className="level-right">
              <button
                className="button is-primary"
                onClick={() => {
                  resetForm();
                  setShowNew(true);
                }}
              >
                New Version
              </button>
            </div>
          </div>

          {showNew && (
            <div className="box">
              <h2 className="subtitle">New Prompt Version</h2>
              <p className="is-size-7 has-text-grey mb-3">
                Parent will be set to the latest active version automatically.
              </p>
              <div className="field">
                <label className="label">Name</label>
                <input
                  className="input"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
              </div>
              <div className="field">
                <label className="label">Change notes</label>
                <input
                  className="input"
                  value={form.changeNotes}
                  onChange={(e) =>
                    setForm({ ...form, changeNotes: e.target.value })
                  }
                />
              </div>
              <div className="field">
                <label className="label">Subject headings task</label>
                <textarea
                  className="textarea"
                  rows={5}
                  value={form.subjectPrompt}
                  onChange={(e) =>
                    setForm({ ...form, subjectPrompt: e.target.value })
                  }
                />
              </div>
              <div className="field">
                <label className="label">Description task</label>
                <textarea
                  className="textarea"
                  rows={4}
                  value={form.descriptionPrompt}
                  onChange={(e) =>
                    setForm({ ...form, descriptionPrompt: e.target.value })
                  }
                />
              </div>
              <div className="buttons">
                <button
                  className="button is-primary"
                  onClick={handleSave}
                  disabled={
                    !form.name || !form.subjectPrompt || !form.descriptionPrompt
                  }
                >
                  Save
                </button>
                <button
                  className="button"
                  onClick={() => {
                    setShowNew(false);
                    resetForm();
                  }}
                >
                  Cancel
                </button>
              </div>
            </div>
          )}

          {loading && <progress className="progress is-small is-primary" />}

          {versions.map((v, i) => (
            <PromptVersionCard
              key={v.id}
              v={v}
              isLatest={i === 0}
              onArchive={() => {
                if (confirm(`Archive "${v.name}"?`))
                  archiveVersion({ variables: { id: v.id } });
              }}
            />
          ))}
        </div>
      </section>
    </Layout>
  );
}
