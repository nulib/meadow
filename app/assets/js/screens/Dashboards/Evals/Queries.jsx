import React, { useState } from "react";
import { useQuery, useMutation } from "@apollo/client";
import Layout from "@js/screens/Layout";
import { Breadcrumbs } from "@js/components/UI/UI";
import {
  GET_EVAL_QUERY_LIST,
  CREATE_EVAL_QUERY,
  UPDATE_EVAL_QUERY,
  DELETE_EVAL_QUERY,
} from "@js/components/Dashboards/Evals/evals.gql";

export default function EvalsQueriesScreen() {
  const { data, loading } = useQuery(GET_EVAL_QUERY_LIST);
  const [editing, setEditing] = useState(null);
  const [showNew, setShowNew] = useState(false);
  const [form, setForm] = useState({ name: "", description: "", queryJson: "{}" });
  const [jsonError, setJsonError] = useState(null);

  const [createQuery] = useMutation(CREATE_EVAL_QUERY, { refetchQueries: [{ query: GET_EVAL_QUERY_LIST }] });
  const [updateQuery] = useMutation(UPDATE_EVAL_QUERY, { refetchQueries: [{ query: GET_EVAL_QUERY_LIST }] });
  const [deleteQuery] = useMutation(DELETE_EVAL_QUERY, { refetchQueries: [{ query: GET_EVAL_QUERY_LIST }] });

  const queries = data?.evalQueryList || [];

  const validateJson = (str) => {
    try { JSON.parse(str); setJsonError(null); return true; }
    catch (e) { setJsonError(e.message); return false; }
  };

  const handleSave = async () => {
    if (!validateJson(form.queryJson)) return;
    const vars = { name: form.name, description: form.description, queryJson: form.queryJson };
    if (editing) {
      await updateQuery({ variables: { id: editing.id, ...vars } });
      setEditing(null);
    } else {
      await createQuery({ variables: vars });
      setShowNew(false);
    }
    setForm({ name: "", description: "", queryJson: "{}" });
  };

  const startEdit = (q) => {
    setEditing(q);
    setForm({ name: q.name, description: q.description || "", queryJson: JSON.stringify(q.queryJson, null, 2) });
    setShowNew(false);
  };

  const queries_form = (
    <div className="box">
      <h2 className="subtitle">{editing ? "Edit Query" : "New Query"}</h2>
      <div className="field">
        <label className="label">Name</label>
        <input className="input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
      </div>
      <div className="field">
        <label className="label">Description</label>
        <input className="input" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} />
      </div>
      <div className="field">
        <label className="label">OpenSearch query JSON</label>
        <textarea
          className={`textarea is-family-monospace${jsonError ? " is-danger" : ""}`}
          rows={8}
          value={form.queryJson}
          onChange={(e) => { setForm({ ...form, queryJson: e.target.value }); validateJson(e.target.value); }}
        />
        {jsonError && <p className="help is-danger">{jsonError}</p>}
      </div>
      <div className="buttons">
        <button className="button is-primary" onClick={handleSave} disabled={!!jsonError}>Save</button>
        <button className="button" onClick={() => { setEditing(null); setShowNew(false); }}>Cancel</button>
      </div>
    </div>
  );

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <Breadcrumbs items={[
            { label: "Dashboards", isActive: false },
            { label: "AI Metadata Evals", route: "/dashboards/evals", isActive: false },
            { label: "Manage Queries", route: "/dashboards/evals/queries", isActive: true },
          ]} />
          <div className="level">
            <div className="level-left"><h1 className="title">Eval Queries</h1></div>
            <div className="level-right">
              <button className="button is-primary" onClick={() => { setShowNew(true); setEditing(null); setForm({ name: "", description: "", queryJson: '{"query":{"match_all":{}}}' }); }}>
                New Query
              </button>
            </div>
          </div>

          {showNew && queries_form}

          {loading && <progress className="progress is-small is-primary" />}

          {queries.map((q) => (
            <div key={q.id}>
              {editing?.id === q.id ? queries_form : (
                <div className="box is-flex is-justify-content-space-between is-align-items-center">
                  <div>
                    <strong>{q.name}</strong>
                    {q.description && <p className="is-size-7 has-text-grey">{q.description}</p>}
                    <p className="is-size-7 has-text-grey-light">by {q.author || "unknown"}</p>
                  </div>
                  <div className="buttons">
                    <button className="button is-small is-light" onClick={() => startEdit(q)}>Edit</button>
                    <button className="button is-small is-danger is-outlined" onClick={() => { if (confirm(`Delete "${q.name}"?`)) deleteQuery({ variables: { id: q.id } }); }}>Delete</button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </section>
    </Layout>
  );
}
