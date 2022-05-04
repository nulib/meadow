import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import { GET_BATCH } from "@js/components/Dashboards/dashboards.gql";
import JSONPretty from "react-json-pretty";
import UIDate from "@js/components/UI/Date";
import UISkeleton from "@js/components/UI/Skeleton";
import { Link } from "react-router-dom";
import { IconImages } from "@js/components/Icon";
import { Notification } from "@nulib/design-system";

function DashboardsBatchEditDetails({ id }) {
  const { error, loading, data } = useQuery(GET_BATCH, {
    variables: {
      id,
    },
  });

  if (loading) return <UISkeleton />;
  if (error) {
    return (
      <Notification isDanger data-testid="error-fetching">
        <p>Error fetching batch job id</p>
        <p>{error.toString()}</p>
      </Notification>
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
      <div className="columns content">
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
            <dt>Works {type == "UPDATE" ? "Updated" : "Deleted"}</dt>
            <dd>{worksUpdated}</dd>
          </dl>
        </div>
      </div>
      {worksUpdated && type == "UPDATE" && (
        <Link
          data-testid="button-to-search"
          className="button is-primary"
          to={{
            pathname: "/search",
            state: { passedInSearchTerm: `batches:\"${id}\"` },
          }}
        >
          <IconImages />
          <span>View batch edit works</span>
        </Link>
      )}
      <hr />
      <dl className="spaced">
        {type == "UPDATE" && (
          <React.Fragment>
            <dt>Added</dt>
            <dd>{<JSONPretty data={add} />}</dd>
            <dt>Delete</dt>
            <dd>{<JSONPretty data={jobDelete} />}</dd>
            <dt>Replaced</dt>
            <dd>{<JSONPretty data={replace} />}</dd>
          </React.Fragment>
        )}
        <dt>Error</dt>
        <dd>{<JSONPretty data={jobError} />}</dd>

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
