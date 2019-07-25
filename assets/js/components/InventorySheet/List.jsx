import React from "react";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import gql from "graphql-tag";
import { Query } from "react-apollo";
import Error from "../../screens/Error";
import Loading from "../../screens/Loading";
import { GET_PROJECT_QUERY } from "../../screens/Project/Project"

const InventorySheetList = ({ projectId }) => {
  return (
    <Query query={GET_PROJECT_QUERY} variables={{ projectId }}>
      {({ data, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;
        return <div>
          {data.project.ingestJobs.length === 0 && (
            <p data-testid="no-inventory-sheets-notification">
              No inventory sheets are found.
            </p>
          )}

          {data.project.ingestJobs.length > 0 && (
            <ul data-testid="inventory-sheet-list">
              {data.project.ingestJobs.map(sheet => (
                <li key={sheet.id} className="pb-4">
                  <p>
                    <Link to={`/project/${projectId}/inventory-sheet/${sheet.id}`}>
                      {sheet.name}
                    </Link>
                  </p>
                  <p>Total Works: xxx</p>
                  <p>Ingested: 2019-05-12</p>
                  <p>Creator: Some person</p>
                </li>
              ))}
            </ul>
          )}
        </div>

      }}
    </Query>
  );
};

InventorySheetList.propTypes = {
  projectId: PropTypes.string.isRequired
};

export default InventorySheetList;
