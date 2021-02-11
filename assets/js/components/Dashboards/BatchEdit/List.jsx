import React from "react";
import { useQuery } from "@apollo/client";
import { GET_BATCHES } from "@js/components/Dashboards/dashboards.gql";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";
import UIDate from "@js/components/UI/Date";

const colHeaders = [
  "Nickname",
  "Type",
  "Started",
  "User",
  "Works Updated",
  "Status",
];

function Status({ status }) {
  let statusClass = "";

  switch (status) {
    case "COMPLETE":
      statusClass = "is-success";
      break;
    case "ERROR":
      statusClass = "is-danger";
      break;
    case "IN_PROGRESS":
      statusClass = "is-warning";
      break;
    default:
      break;
  }

  return <span className={`tag ${statusClass} is-light`}>{status}</span>;
}

export default function DashboardsBatchEditTable() {
  const { loading, error, data } = useQuery(GET_BATCHES, { pollInterval: 500 });
  const batches =
    data &&
    data.batches
      .slice() // slice to unfreeze array
      .sort((a, b) => {
        return new Date(a.started).getTime() - new Date(b.started).getTime();
      })
      .reverse();

  if (loading) return null;
  if (error) return `Error: ${error}`;

  return (
    <table
      className="table is-striped is-fullwidth"
      data-testid="batch-dashboard-table"
    >
      <thead>
        <tr>
          <th className="is-hidden"></th>
          {colHeaders.map((col) => (
            <th key={col}>{col}</th>
          ))}
          <th></th>
        </tr>
      </thead>
      <tbody data-testid="batch-dashboard-table-body">
        {batches.map((record) => {
          const {
            id,
            nickname,
            query,
            started,
            status,
            type,
            user,
            worksUpdated,
          } = record;

          return (
            <tr key={id} data-testid="batches-row">
              <td className="is-hidden">{id}</td>
              <td>{nickname}</td>
              <td>{type}</td>
              <td>
                <UIDate dateString={started} />
              </td>
              <td>{user}</td>
              <td>{worksUpdated}</td>
              <td>
                <Status status={status} />
              </td>
              <td className="has-text-right">
                <Link
                  className="button is-small mr-1"
                  to={`/dashboards/batch-edit/${id}`}
                  data-testid="view-button"
                >
                  <FontAwesomeIcon icon="eye" />
                </Link>
                {type == "UPDATE" && (
                  <Link
                    data-testid="button-to-search"
                    className="button is-small"
                    title="View updated works"
                    to={{
                      pathname: "/search",
                      state: { passedInSearchTerm: `batches:\"${id}\"` },
                    }}
                  >
                    <FontAwesomeIcon icon="share" />
                  </Link>
                )}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
