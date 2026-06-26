import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { useQuery } from "@apollo/client/react";
import {
  OriginBadge,
  StatusPill,
  ProvenanceValue,
  ProvenanceEvents,
} from "@js/components/AIProvenance/Badges";
import { AIProvenanceBadgesAlwaysVisible } from "@js/context/ai-provenance-context";
import { GET_AI_ACTIVITY } from "./provenance.gql";

export default function DashboardsProvenanceDetails({ id }) {
  const { data, loading } = useQuery(GET_AI_ACTIVITY, {
    variables: { id },
    skip: !id,
  });

  if (loading) return <progress className="progress is-small is-primary" />;

  const activity = data?.aiActivity;
  if (!activity) {
    return <div className="notification is-light">AI activity not found.</div>;
  }

  return (
    <AIProvenanceBadgesAlwaysVisible>
      <div data-testid="provenance-dashboard-details">
        <div className="box">
          <div className="is-flex is-justify-content-space-between is-align-items-center">
            <div>
              <h2 className="title is-5 mb-1">{activity.activityType}</h2>
              <p className="has-text-grey is-size-7">
                {activity.aiUseType} · {activity.model || "no model"}
                {activity.accessMode ? ` · ${activity.accessMode}` : ""}
                {activity.reversibility ? ` · ${activity.reversibility}` : ""}
              </p>
            </div>
            <StatusPill status={activity.status} />
          </div>
          {activity.workId && (
            <p className="is-size-7 mt-2">
              Work:{" "}
              <Link to={`/work/${activity.workId}`}>{activity.workId}</Link>
            </p>
          )}
          {activity.error && (
            <p className="has-text-danger is-size-7 mt-2">{activity.error}</p>
          )}
        </div>

        {activity.sources?.length > 0 && (
          <div className="box">
            <h3 className="title is-6">Sources</h3>
            <ul>
              {activity.sources.map((source) => (
                <li key={source.id} className="is-size-7">
                  {source.itemType} {source.itemId}
                  {source.collectionTitle ? ` · ${source.collectionTitle}` : ""}
                  {source.holdingOrganization
                    ? ` · ${source.holdingOrganization}`
                    : ""}
                  {source.restricted ? " · restricted" : ""}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="box">
          <h3 className="title is-6">Targets &amp; events</h3>
          <div className="table-container">
            <table
              className="table is-striped is-hoverable is-fullwidth"
              data-testid="provenance-targets-table"
            >
              <thead>
                <tr>
                  <th>Field</th>
                  <th>Operation</th>
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
                    <td className="is-size-7">{target.operation || "—"}</td>
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
      </div>
    </AIProvenanceBadgesAlwaysVisible>
  );
}

DashboardsProvenanceDetails.propTypes = {
  id: PropTypes.string,
};
