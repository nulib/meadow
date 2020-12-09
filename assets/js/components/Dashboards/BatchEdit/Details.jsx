import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { GET_BATCH } from "@js/components/Dashboards/dashboards.gql";
import JSONPretty from "react-json-pretty";
import UIDate from "@js/components/UI/Date";
import UISkeleton from "@js/components/UI/Skeleton";

function DashboardsBatchEditDetails({ id }) {
  const { error, loading, data } = useQuery(GET_BATCH, {
    variables: {
      id,
    },
  });

  if (loading) return <UISkeleton />;
  if (error) {
    return (
      <div
        className="notification is-danger is-light"
        data-testid="error-fetching"
      >
        <p>Error fetching batch job id</p>
        <p>{error.toString()}</p>
      </div>
    );
  }

  const {
    batch: {
      add,
      delete: jobDelete,
      error: jobError,
      id: jobId,
      nickname,
      query,
      replace,
      started,
      status,
      type,
      user,
      worksUpdated,
    },
  } = data;

  return (
    <section data-testid="batch-details">
      <div className="columns">
        <div className="column">
          <dl className="spaced">
            <dt>Nickname</dt>
            <dd>{nickname}</dd>
            <dt>Status</dt>
            <dd>{status}</dd>
            <dt>Started</dt>
            <dd>
              <UIDate dateString={started} />
            </dd>
          </dl>
        </div>
        <div className="column">
          <dl className="spaced">
            <dt>Type</dt>
            <dd>{type}</dd>
            <dt>User</dt>
            <dd>{user}</dd>
            <dt>Works Updated</dt>
            <dd>{worksUpdated}</dd>
          </dl>
        </div>
      </div>

      <hr />
      <dl className="spaced">
        <dt>Added</dt>
        <dd>{<JSONPretty data={add} />}</dd>
        <dt>Delete</dt>
        <dd>{<JSONPretty data={jobDelete} />}</dd>
        <dt>Error</dt>
        <dd>{<JSONPretty data={jobError} />}</dd>
        <dt>Replaced</dt>
        <dd>{<JSONPretty data={replace} />}</dd>
        <dt>ElasticSearch query</dt>
        <dd>{<JSONPretty data={query} />}</dd>
      </dl>
    </section>
  );
}

DashboardsBatchEditDetails.propTypes = {
  batch: PropTypes.object,
};

export default DashboardsBatchEditDetails;
