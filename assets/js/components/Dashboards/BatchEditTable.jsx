import React from "react";
import { useQuery } from "@apollo/client";
import { GET_BATCHES } from "@js/components/Dashboards/dashboards.gql";
import moment from "moment";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Link } from "react-router-dom";

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

export default function BatchEditTable() {
  const { loading, error, data } = useQuery(GET_BATCHES, { pollInterval: 500 });

  if (loading) return null;
  if (error) return `Error: ${error}`;

  return (
    <table
      className="table is-striped is-fullwidth"
      data-testid="batch-dashboard-table"
    >
      <thead>
        <tr>
          {colHeaders.map((col) => (
            <th key={col}>{col}</th>
          ))}
          <th></th>
        </tr>
      </thead>
      <tbody data-testid="batch-dashboard-table-body">
        {data.batches.map((record) => {
          const {
            add,
            delete: deleteValue,
            error,
            id,
            nickname,
            query,
            replace,
            started,
            status,
            type,
            user,
            worksUpdated,
          } = record;

          return (
            <tr key={id} data-testid="batches-row">
              <td>{nickname}</td>
              <td>{type}</td>
              <td>{moment(started).format("MMM DD, YYYY h:mm A")}</td>
              <td>{user}</td>
              <td className="has-text-right">{worksUpdated}</td>
              <td>
                <Status status={status} />
              </td>
              <td className="has-text-right">
                <Link
                  className="button"
                  to={`/dashboards/${id}`}
                  data-testid="view-button"
                >
                  <FontAwesomeIcon icon="eye" />
                </Link>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
