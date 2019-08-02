import React from "react";
import { withRouter } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import ButtonGroup from "../../components/UI/ButtonGroup";
import UIButton from "../../components/UI/Button";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import gql from "graphql-tag";
import { Query } from "react-apollo";

const GET_CRUMB_DATA = gql`
  query getCrumbData($projectId: String!, $inventorySheetId: String!) {
    project(id: $projectId) {
      title
    }
    ingestJob(id: $inventorySheetId) {
      name
      insertedAt
      updatedAt
      filename
    }
  }
`;

const ScreensInventorySheet = ({ match }) => {
  const { id, inventorySheetId } = match.params;

  return (
    <Query
      query={GET_CRUMB_DATA}
      variables={{ projectId: id, inventorySheetId }}
    >
      {({ data, loading, error }) => {
        if (error) return <Error error={error} />;
        if (loading) return <Loading />;

        const { project, ingestJob } = data;

        const createCrumbs = () => {
          return [
            {
              label: "Projects",
              link: "/project/list"
            },
            {
              label: project.title,
              link: `/project/${id}`
            },
            {
              label: ingestJob.name,
              link: `/project/${id}/inventory-sheet/${inventorySheetId}`
            }
          ];
        };

        return (
          <>
            <ScreenHeader
              title="Inventory Sheet"
              description="The following is system validation/parsing of the .csv Inventory sheet.  Currently it checks 1.) Is it a .csv file?  2.) Are the appropriate headers present?  3.) Do files exist in AWS S3?"
              breadCrumbs={createCrumbs()}
            />
            <ScreenContent>
              <img className="w-screen" src="/images/placeholder-content.png" />
              <h3 className="italic pt-8">Coming Soon...</h3>
              <ButtonGroup>
                <UIButton label="Looks great, approve the sheet" />
                <UIButton classes="bg-red-500" label="Eject and start over" />
              </ButtonGroup>
            </ScreenContent>
          </>
        );
      }}
    </Query>
  );
};

export default withRouter(ScreensInventorySheet);
export { GET_CRUMB_DATA };
