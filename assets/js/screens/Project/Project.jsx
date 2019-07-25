import React from "react";
import { withRouter } from "react-router";
import InventorySheetList from "../../components/InventorySheet/List";
import { Link } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../Error";
import Loading from "../Loading";
import gql from "graphql-tag";
import { Query } from "react-apollo";

const GET_PROJECT_QUERY = gql`
  query GetProject($projectId: String!) {
    project(id: $projectId) {
      id
      title
      ingestJobs {
        id
        name
      }
    }
  }
`;

const Project = ({ match }) => {
  const { id } = match.params;

  return (
    <Query query={GET_PROJECT_QUERY} variables={{ projectId: id }}>
      {({ data, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;
        return <div>
          {
            data.project && (
              <>
                <ScreenHeader title={`Project: ${data.project.title}`} description="The following is a list of all active Ingest Jobs (or Inventory sheets) for a project" />

                <ScreenContent>

                  <Link
                    to={{
                      pathname: `/project/${id}/inventory-sheet/upload`,
                      state: { projectId: data.project.id }
                    }}
                    className="btn mb-4">
                    New Ingest Job
                  </Link>
                  <h2>Ingest Jobs</h2>
                  <section>
                    <InventorySheetList projectId={data.project.id} />
                  </section>
                </ScreenContent>
              </>
            )
          }
        </div>
      }}
    </Query>
  );
};

export default withRouter(Project);

export { GET_PROJECT_QUERY };
