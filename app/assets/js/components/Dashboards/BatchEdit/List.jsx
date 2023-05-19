import { IconImages, IconView } from "@js/components/Icon";

import { GET_BATCHES } from "@js/components/Dashboards/dashboards.gql";
import { Link } from "react-router-dom";
import React from "react";
import { Tag } from "@nulib/design-system";
import UIDate from "@js/components/UI/Date";
import { useQuery } from "@apollo/client";

const colHeaders = [
  "Nickname",
  "Type",
  "Started",
  "User",
  "Works Updated",
  "Status",
];

export default function DashboardsBatchEditList() {
  const { loading, error, data } = useQuery(GET_BATCHES, { pollInterval: 500 });
  if (loading) return null;
  if (error) return `Error: ${error}`;

  const sortedBatches = [...data.batches].sort((a, b) =>
    a.started < b.started ? 1 : -1
  );

  return (
    <div className="table-container">
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
          {sortedBatches.map((record) => {
            const { id, nickname, started, status, type, user, worksUpdated } =
              record;

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
                  <Tag
                    isSuccess={status === "COMPLETE"}
                    isDanger={status === "ERROR"}
                    isWarning={status === "IN_PROGRESS"}
                  >
                    {status}
                  </Tag>
                </td>
                <td>
                  <div className="field is-grouped is-justify-content-flex-end">
                    <Link
                      className="button is-light"
                      to={`/dashboards/batch-edit/${id}`}
                      data-testid="view-button"
                      title="View Batch Edit details"
                    >
                      <IconView />
                    </Link>
                    {type == "UPDATE" && (
                      <Link
                        data-testid="button-to-search"
                        className="button is-light"
                        title="View updated works"
                        to={{
                          pathname: "/search",
                          state: { passedInSearchTerm: `batch_ids:\"${id}\"` },
                        }}
                      >
                        <IconImages />
                      </Link>
                    )}
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
