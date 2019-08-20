import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import gql from "graphql-tag";
import { Query } from "react-apollo";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";

const GET_INGEST_JOBS = gql`
  query GetIngestJobs($projectId: ID!) {
    project(id: $projectId) {
      id
      ingestJobs {
        id
        name
        updatedAt
      }
    }
  }
`;

const InventorySheetList = ({ projectId }) => {
  const { loading, error, data } = useQuery(GET_INGEST_JOBS, {
    variables: { projectId }
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <div>
      {data.project.ingestJobs.length === 0 && (
        <p data-testid="no-inventory-sheets-notification">
          No inventory sheets are found.
        </p>
      )}

      {data.project.ingestJobs.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Ingest job title</th>
              <th>Last updated</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {data.project.ingestJobs.map(
              ({ id, name, filename, updatedAt }) => (
                <tr key={id}>
                  <td>
                    <Link to={`/project/${projectId}/inventory-sheet/${id}`}>
                      {name}
                    </Link>
                  </td>
                  <td>{updatedAt}</td>
                  <td>...tbd</td>
                </tr>
              )
            )}
          </tbody>
        </table>
      )}
    </div>
  );
};

InventorySheetList.propTypes = {
  projectId: PropTypes.string.isRequired
};

export default InventorySheetList;
