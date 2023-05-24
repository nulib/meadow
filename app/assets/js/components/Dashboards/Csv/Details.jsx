import DashboardsCsvErrors from "@js/components/Dashboards/Csv/Errors";
import DashboardsCsvStatus from "@js/components/Dashboards/Csv/Status";
import { IconImages } from "@js/components/Icon";
import { Link } from "react-router-dom";
import PropTypes from "prop-types";
import React from "react";
import UIDate from "@js/components/UI/Date";

function DashboardsCsvDetails({ csvMetadataUpdateJob }) {
  const {
    id: updateId,
    errors,
    filename,
    insertedAt,
    rows,
    source,
    startedAt,
    status,
    updatedAt,
    user,
  } = csvMetadataUpdateJob;

  return (
    <>
      <div className="subtitle" data-testid="csv-job-status-wrapper">
        <DashboardsCsvStatus status={status} />
      </div>
      <section data-testid="csv-job-details">
        <div className="columns">
          <div className="column">
            <dl className="spaced">
              <dt>Filename</dt>
              <dd>{filename}</dd>
              <dt>Status</dt>
              <dd>{status}</dd>
              <dt>Started</dt>
              <dd>
                <UIDate dateString={startedAt} />
              </dd>
              <dt>Total rows</dt>
              <dd>{rows}</dd>
            </dl>
          </div>
          <div className="column">
            <dl className="spaced">
              <dt>User</dt>
              <dd>{user}</dd>
              <dt>Inserted At</dt>
              <dd>
                <UIDate dateString={insertedAt} />
              </dd>
              <dt>Updated At</dt>
              <dd>
                <UIDate dateString={updatedAt} />
              </dd>
            </dl>
          </div>
        </div>
      </section>

      {status.toUpperCase() === "COMPLETE" && (
        <Link
          data-testid="button-to-search"
          className="button"
          title="View updated works"
          to={{
            pathname: "/search",
            state: {
              passedInSearchTerm: `csv_metadata_update_jobs:\"${updateId}\"`,
            },
          }}
        >
          <IconImages />
          <span>View CSV import works</span>
        </Link>
      )}

      {errors && errors.length > 0 && <DashboardsCsvErrors errors={errors} />}
    </>
  );
}

DashboardsCsvDetails.propTypes = {
  id: PropTypes.string,
};

export default DashboardsCsvDetails;
