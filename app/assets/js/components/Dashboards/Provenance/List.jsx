import React, { useState } from "react";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/client/react";
import { StatusPill } from "@js/components/AIProvenance/Badges";
import { GET_AI_ACTIVITIES } from "./provenance.gql";

const ACTIVITY_TYPES = [
  "metadata_plan",
  "metadata_direct_apply",
  "legacy_note_cleanup",
];
const STATUSES = ["completed", "pending", "failed"];

function formatDate(value) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}

function formatCost(value) {
  if (value == null) return "—";
  return `$${Number(value).toFixed(4)}`;
}

export default function DashboardsProvenanceList() {
  const [filters, setFilters] = useState({ activityType: "", status: "" });

  const { data, loading } = useQuery(GET_AI_ACTIVITIES, {
    variables: {
      activityType: filters.activityType || null,
      status: filters.status || null,
      limit: 100,
    },
  });

  const activities = data?.aiActivities || [];

  const handleFilter = (key) => (e) =>
    setFilters((f) => ({ ...f, [key]: e.target.value }));

  return (
    <div data-testid="provenance-dashboard-list">
      <div className="field is-grouped mb-4">
        <div className="control">
          <div className="select">
            <select
              data-testid="filter-activity-type"
              value={filters.activityType}
              onChange={handleFilter("activityType")}
            >
              <option value="">All activity types</option>
              {ACTIVITY_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>
        </div>
        <div className="control">
          <div className="select">
            <select
              data-testid="filter-status"
              value={filters.status}
              onChange={handleFilter("status")}
            >
              <option value="">All statuses</option>
              {STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {loading && <progress className="progress is-small is-primary" />}

      {activities.length === 0 && !loading ? (
        <div className="notification is-light">
          No AI activities match the current filters.
        </div>
      ) : (
        <div className="table-container">
          <table className="table is-striped is-hoverable is-fullwidth">
            <thead>
              <tr>
                <th>Activity</th>
                <th>Use</th>
                <th>Model</th>
                <th>Status</th>
                <th>Work</th>
                <th>Cost</th>
                <th>Started</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {activities.map((activity) => (
                <tr key={activity.id}>
                  <td className="is-size-7">{activity.activityType}</td>
                  <td className="is-size-7">{activity.aiUseType || "—"}</td>
                  <td className="is-size-7">{activity.model || "—"}</td>
                  <td>
                    <StatusPill status={activity.status} />
                  </td>
                  <td className="is-size-7">
                    {activity.workId ? (
                      <Link to={`/work/${activity.workId}`}>
                        {activity.workId.slice(0, 8)}
                      </Link>
                    ) : (
                      "—"
                    )}
                  </td>
                  <td className="is-size-7">{formatCost(activity.costUsd)}</td>
                  <td className="is-size-7">
                    {formatDate(activity.startedAt || activity.insertedAt)}
                  </td>
                  <td>
                    <Link
                      to={`/dashboards/ai-provenance/${activity.id}`}
                      className="button is-small is-light"
                    >
                      View
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
