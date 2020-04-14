import React from "react";
import { useParams } from "react-router";
import Layout from "../Layout";
import IngestSheetList from "../../components/IngestSheet/List";
import { Link } from "react-router-dom";
import Error from "../../components/UI/Error";
import UILoadingPage from "../../components/UI/LoadingPage";
import { useQuery } from "@apollo/react-hooks";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import {
  GET_PROJECT,
  INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION
} from "../../components/Project/project.query";
import { formatDate } from "../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const ScreensProject = () => {
  const { id } = useParams();
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

  if (loading) return <UILoadingPage />;
  if (error) return <Error error={error} />;

  const breadCrumbs = [
    {
      label: "Projects",
      route: "/project/list"
    },
    {
      label: `${data.project.title}`,
      route: `/project/${data.project.id}`,
      isActive: true
    }
  ];

  return (
    <Layout>
      {data.project && (
        <div>
          <section className="section">
            <div className="container">
              <UIBreadcrumbs
                items={breadCrumbs}
                data-testid="project-breadcrumbs"
              />
              <div className="columns" data-testid="screen-header">
                <div className="column is-two-thirds">
                  <div className="box">
                    <h1 className="title">{data.project.title}</h1>
                    <h2 className="subtitle">
                      Last updated:{" "}
                      <span className="is-italic">
                        {formatDate(data.project.updatedAt)}
                      </span>
                    </h2>
                  </div>
                </div>
                <div className="column is-one-third">
                  <div className="box content">
                    <p>[x] Ingest Sheets in project</p>
                    <p>
                      <Link
                        to={{
                          pathname: `/project/${id}/ingest-sheet/upload`,
                          state: { projectId: data.project.id }
                        }}
                        className="button is-primary"
                        data-testid="button-new-ingest-sheet"
                      >
                        <span className="icon">
                          <FontAwesomeIcon icon="file-csv" />
                        </span>{" "}
                        <span>Add an Ingest Sheet</span>
                      </Link>
                    </p>
                  </div>
                </div>
              </div>
              <div className="box" data-testid="screen-content">
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
              </div>
            </div>
          </section>
        </div>
      )}
    </Layout>
  );
};

export default ScreensProject;
