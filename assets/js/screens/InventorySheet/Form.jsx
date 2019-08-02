import React from "react";
import { withRouter } from "react-router-dom";
import InventorySheetForm from "../../components/InventorySheet/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import gql from "graphql-tag";
import { Query } from "react-apollo";

const GET_PROJECT_QUERY = gql`
  query GetProject($projectId: String!) {
    project(id: $projectId) {
      title
    }
  }
`;

const ScreensInventorySheetForm = ({ match }) => {
  const { id } = match.params;

  return (
    <Query query={GET_PROJECT_QUERY} variables={{ projectId: id }}>
      {({ data, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;

        const { project } = data;

        return (
          <>
            <ScreenHeader
              title="New Ingest Job"
              description="Upload an Inventory sheet here to validate its contents and its work files exist in AWS"
              breadCrumbs={[
                {
                  label: "Projects",
                  link: "/project/list"
                },
                {
                  label: project.title,
                  link: `/project/${id}`
                },
                {
                  label: "Create ingest job",
                  link: `/project/${id}/inventory-sheet/upload`
                }
              ]}
            />

            <ScreenContent>
              {id && <InventorySheetForm projectId={id} />}
            </ScreenContent>
          </>
        );
      }}
    </Query>
  );
};

export default withRouter(ScreensInventorySheetForm);
export { GET_PROJECT_QUERY };
