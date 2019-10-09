import React from "react";
import { withRouter } from "react-router";
import IngestSheetList from "../../components/IngestSheet/List";
import { Link } from "react-router-dom";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Error from "../../components/UI/Error";
import Loading from "../../components/UI/Loading";
import { useQuery } from "@apollo/react-hooks";
import AddOutlineIcon from "../../../css/fonts/zondicons/add-outline.svg";
import {
  GET_PROJECT,
  INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION
} from "../../components/Project/project.query";

const ScreensProject = ({ match }) => {
  const { id } = match.params;
  const { loading, error, data, subscribeToMore } = useQuery(GET_PROJECT, {
    variables: { projectId: id }
  });

  const handleIngestSheetStatusChange = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const ingestSheet = subscriptionData.data.ingestSheetUpdatesForProject;

    let updatedIngestSheets;
    switch (ingestSheet.status) {
      case "UPLOADED":
        updatedIngestSheets = [ingestSheet, ...prev.project.ingestSheets];
        break;
      case "DELETED":
        updatedIngestSheets = prev.project.ingestSheets.filter(
          i => i.id !== ingestSheet.id
        );
        break;
      default:
        updatedIngestSheets = prev.project.ingestSheets.filter(
          i => i.id !== ingestSheet.id
        );
        updatedIngestSheets = [ingestSheet, ...updatedIngestSheets];
    }

    return {
      project: {
        ...prev.project,
        ingestSheets: updatedIngestSheets
      }
    };
  };

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <div>
      {data.project && (
        <>
          <ScreenHeader
            title={data.project.title}
            description="The following is a list of all active Ingest Sheets for a project"
            breadCrumbs={[
              {
                label: "Projects",
                link: "/project/list"
              },
              {
                label: `${data.project.title}`,
                link: `/project/${data.project.id}`
              }
            ]}
          />

          <ScreenContent>
            <Link
              to={{
                pathname: `/project/${id}/ingest-sheet/upload`,
                state: { projectId: data.project.id }
              }}
              className="btn mb-4"
              data-testid="button-new-ingest-sheet"
            >
              <AddOutlineIcon className="icon" /> New Ingest Sheet
            </Link>

            <section>
              <IngestSheetList
                project={data.project}
                subscribeToIngestSheetStatusChanges={() =>
                  subscribeToMore({
                    document: INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
                    variables: { projectId: data.project.id },
                    updateQuery: handleIngestSheetStatusChange
                  })
                }
              />
            </section>
          </ScreenContent>
        </>
      )}
    </div>
  );
};

export default withRouter(ScreensProject);
