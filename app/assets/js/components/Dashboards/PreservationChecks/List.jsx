import React from "react";
import { useLazyQuery, useQuery } from "@apollo/client/react";
import { GET_PRESERVATION_CHECKS } from "@js/components/Dashboards/dashboards.gql";
import UIDate from "@js/components/UI/Date";
import { IconDownload } from "@js/components/Icon";
import { GET_PRESIGNED_URL } from "@js/components/IngestSheet/ingestSheet.gql.js";
import { Tag } from "@nulib/design-system";

const colHeaders = [
  "Started",
  "Completed",
  "Job Status",
  "Errors",
  "Filename",
  "",
];

export default function DashboardsPreservationChecksList() {
  const { loading, error, data } = useQuery(GET_PRESERVATION_CHECKS, {
    pollInterval: 50000,
  });

  const [
    getPresignedUrl,
    { presignedUrlError, presignedUrlLoading, presignedUrlData },
  ] = useLazyQuery(GET_PRESIGNED_URL, {
    onCompleted: (data) => {
      window.location.href = data.presignedUrl.url;
    },
  });
  if (loading) return null;
  if (error) return `Error: ${error}`;

  const handleDownloadClick = (filename) => {
    getPresignedUrl({
      variables: {
        uploadType: "PRESERVATION_CHECK",
        filename: filename,
      },
      fetchPolicy: "no-cache",
    });
  };

  const sortedPreservationChecks = [...data.preservationChecks].sort((a, b) =>
    a.insertedAt < b.insertedAt ? 1 : -1
  );

  return (
    <table
      className="table is-striped is-fullwidth"
      data-testid="preservation-checks-dashboard-table"
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
      <tbody data-testid="preservation-checks-dashboard-table-body">
        {sortedPreservationChecks.map((record) => {
          const { id, insertedAt, updatedAt, status, invalidRows, filename } =
            record;
          return (
            <tr key={id} data-testid="preservation-check-row">
              <td className="is-hidden">{id}</td>
              <td>
                <UIDate dateString={insertedAt} />
              </td>
              <td>
                {status === "complete" && <UIDate dateString={updatedAt} />}
              </td>
              <td>
                <Tag
                  isSuccess={status === "complete"}
                  isDanger={status === "error" || status === "timeout"}
                  isWarning={status === "in_progress"}
                >
                  {status}
                </Tag>
              </td>
              <td>{status === "complete" && invalidRows}</td>
              <td>{status === "complete" && filename}</td>
              <td className="has-text-right">
                {status === "complete" && (
                  <a
                    className="button is-light mr-1"
                    data-testid="download-button"
                    onClick={() => handleDownloadClick(filename)}
                    title="Download CSV"
                  >
                    <IconDownload />
                  </a>
                )}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
