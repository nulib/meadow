import React, { useState } from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client/react";
import { TabsStickyHeader } from "@js/components/UI/UI";
import {
  OriginBadge,
  StatusPill,
  ProvenanceValue,
  ProvenanceEvents,
} from "@js/components/AIProvenance/Badges";
import { GET_WORK_AI_ACTIVITIES } from "./provenance.gql";

function formatDate(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}

function SummaryTable({ summary }) {
  return (
    <div className="table-container">
      <table
        className="table is-striped is-hoverable is-fullwidth"
        data-testid="provenance-summary-table"
      >
        <thead>
          <tr>
            <th>Field</th>
            <th>Value</th>
            <th>Origin</th>
            <th>Status</th>
            <th>Model</th>
            <th>Reviewer</th>
            <th>Generated</th>
            <th>Applied</th>
            <th>Sources</th>
          </tr>
        </thead>
        <tbody>
          {summary.map((entry) => (
            <tr key={`${entry.activityId}-${entry.fieldPath}`}>
              <td>
                <code>{entry.fieldPath}</code>
              </td>
              <td>
                <ProvenanceValue
                  value={entry.proposedValue}
                  itemProvenance={entry.itemProvenance}
                />
              </td>
              <td>
                <OriginBadge origin={entry.origin} />
              </td>
              <td>
                <StatusPill status={entry.status} />
              </td>
              <td className="is-size-7">{entry.model || "—"}</td>
              <td className="is-size-7">{entry.reviewer || "—"}</td>
              <td className="is-size-7">{formatDate(entry.generatedAt)}</td>
              <td className="is-size-7">{formatDate(entry.appliedAt)}</td>
              <td className="is-size-7">
                {entry.sourceCount ?? 0}
                {entry.citationCompleteness
                  ? ` (${entry.citationCompleteness})`
                  : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

SummaryTable.propTypes = {
  summary: PropTypes.array,
};

function fileSetLabel(fileSet) {
  if (!fileSet) return null;
  return (
    fileSet.coreMetadata?.label || fileSet.accessionNumber || fileSet.id || null
  );
}

function ActivityLog({ activities, fileSets = [] }) {
  if (!activities.length) return null;

  const fileSetsById = fileSets.reduce((acc, fileSet) => {
    if (fileSet?.id) acc[fileSet.id] = fileSet;
    return acc;
  }, {});

  return (
    <div className="content" data-testid="provenance-activity-log">
      <h3 className="title is-5">Activity log</h3>
      {activities.map((activity) => {
        const label = fileSetLabel(fileSetsById[activity.fileSetId]);
        return (
          <div key={activity.id} className="box">
            <div className="is-flex is-justify-content-space-between is-align-items-center mb-2">
              <div>
                <strong>{activity.activityType}</strong>
                {activity.aiUseType && (
                  <span className="has-text-grey is-size-7">
                    {" "}
                    · {activity.aiUseType}
                  </span>
                )}
                {activity.model && (
                  <span className="has-text-grey is-size-7">
                    {" "}
                    · {activity.model}
                  </span>
                )}
                {label && (
                  <span
                    className="tag is-light ml-2"
                    data-testid="provenance-activity-file-set"
                  >
                    {label}
                  </span>
                )}
              </div>
              <StatusPill status={activity.status} />
            </div>
            <div className="table-container">
              <table className="table is-striped is-fullwidth">
                <thead>
                  <tr>
                    <th>Field</th>
                    <th>Value</th>
                    <th>Origin</th>
                    <th>Status</th>
                    <th>Events</th>
                  </tr>
                </thead>
                <tbody>
                  {(activity.targets || []).map((target) => (
                    <tr key={target.id}>
                      <td>
                        <code>{target.fieldPath}</code>
                      </td>
                      <td>
                        <ProvenanceValue value={target.proposedValue} />
                      </td>
                      <td>
                        <OriginBadge origin={target.origin} />
                      </td>
                      <td>
                        <StatusPill status={target.status} />
                      </td>
                      <td>
                        <ProvenanceEvents events={target.events} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        );
      })}
    </div>
  );
}

ActivityLog.propTypes = {
  activities: PropTypes.array,
  fileSets: PropTypes.array,
};

const WorkTabsProvenance = ({ work }) => {
  const [showLog, setShowLog] = useState(false);
  const summary = work?.aiProvenanceSummary || [];

  const { data, loading } = useQuery(GET_WORK_AI_ACTIVITIES, {
    variables: { workId: work?.id },
    skip: !showLog || !work?.id,
  });

  const activities = data?.aiActivities || [];

  if (summary.length === 0) {
    return (
      <div data-testid="provenance-tab">
        <TabsStickyHeader title="AI Provenance" />
        <div className="notification is-light" data-testid="provenance-empty">
          No AI provenance recorded for this work.
        </div>
      </div>
    );
  }

  return (
    <div data-testid="provenance-tab">
      <TabsStickyHeader title="AI Provenance">
        <button
          className="button is-light"
          data-testid="toggle-activity-log"
          onClick={() => setShowLog((v) => !v)}
        >
          {showLog ? "Hide activity log" : "View activity log"}
        </button>
      </TabsStickyHeader>

      <SummaryTable summary={summary} />

      {showLog && loading && (
        <progress className="progress is-small is-primary" />
      )}
      {showLog && (
        <ActivityLog activities={activities} fileSets={work?.fileSets || []} />
      )}
    </div>
  );
};

WorkTabsProvenance.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsProvenance;
