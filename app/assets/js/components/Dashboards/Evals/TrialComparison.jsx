import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faScaleBalanced } from "@fortawesome/free-solid-svg-icons";

function SubjectList({ subjects }) {
  if (!subjects || subjects.length === 0) {
    return <span className="has-text-grey">(none)</span>;
  }
  return (
    <ul style={{ listStyle: "none", padding: 0, margin: 0 }}>
      {subjects.map((s, i) => {
        const label = s.label || s.id || "";
        const id = s.id || "";
        const isUrl = id.startsWith("http://") || id.startsWith("https://");
        return (
          <li key={i} style={{ marginBottom: "0.5rem" }}>
            <span>{label}</span>
            {id && (
              <div>
                {isUrl ? (
                  <a
                    href={id}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="is-size-7 has-text-grey-dark"
                    style={{ fontFamily: "monospace", wordBreak: "break-all" }}
                  >
                    {id}
                  </a>
                ) : (
                  <span
                    className="is-size-7 has-text-grey"
                    style={{ fontFamily: "monospace" }}
                  >
                    {id}
                  </span>
                )}
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}

function DescriptionBlock({ description }) {
  const paragraphs = Array.isArray(description)
    ? description.filter(Boolean)
    : description
      ? [description]
      : [];

  if (paragraphs.length === 0) {
    return <span className="has-text-grey">(none)</span>;
  }

  return (
    <div style={{ maxHeight: "24rem", overflowY: "auto" }}>
      {paragraphs.map((p, i) => (
        <p key={i} style={{ whiteSpace: "pre-wrap", marginBottom: "0.5rem" }}>
          {p}
        </p>
      ))}
    </div>
  );
}

export default function TrialComparison({
  groundTruth,
  agentOutput,
  judgeRationale,
}) {
  const gt = groundTruth || {};
  const ai = agentOutput || {};

  return (
    <div style={{ padding: "1rem 0" }}>
      <div className="columns">
        <div className="column">
          <div className="box" style={{ height: "100%" }}>
            <p className="heading has-text-grey">Ground Truth</p>
            <p className="label is-small">Description</p>
            <DescriptionBlock description={gt.description} />
            <p className="label is-small mt-4">Subjects</p>
            <SubjectList subjects={gt.subjects} />
          </div>
        </div>
        <div className="column">
          <div className="box" style={{ height: "100%" }}>
            <p className="heading has-text-grey">AI output</p>
            <p className="label is-small">Description</p>
            <DescriptionBlock description={ai.description} />
            <p className="label is-small mt-4">Subjects</p>
            <SubjectList subjects={ai.subjects} />
          </div>
        </div>
      </div>
      {judgeRationale && (
        <div className="notification is-light is-size-7">
          <strong>
            <FontAwesomeIcon
              icon={faScaleBalanced}
              style={{ marginRight: "0.35rem" }}
            />
            Judge:
          </strong>{" "}
          {judgeRationale}
        </div>
      )}
    </div>
  );
}

TrialComparison.propTypes = {
  groundTruth: PropTypes.shape({
    description: PropTypes.oneOfType([
      PropTypes.string,
      PropTypes.arrayOf(PropTypes.string),
    ]),
    subjects: PropTypes.arrayOf(
      PropTypes.shape({ id: PropTypes.string, label: PropTypes.string }),
    ),
  }),
  agentOutput: PropTypes.shape({
    description: PropTypes.string,
    subjects: PropTypes.arrayOf(
      PropTypes.shape({ id: PropTypes.string, label: PropTypes.string }),
    ),
  }),
  judgeRationale: PropTypes.string,
};
