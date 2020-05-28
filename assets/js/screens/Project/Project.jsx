import React from "react";
import { useParams } from "react-router";
import Layout from "../Layout";
import IngestSheetList from "../../components/IngestSheet/List";
import { Link } from "react-router-dom";
import Error from "../../components/UI/Error";
import UISkeleton from "../../components/UI/Skeleton";
import { useQuery } from "@apollo/react-hooks";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import {
  GET_PROJECT,
  INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
} from "../../components/Project/project.gql.js";
import { formatDate } from "../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

const ScreensProject = () => {
  const { id } = useParams();
  const { loading, error, data, subscribeToMore } = useQuery(GET_PROJECT, {
    variables: { projectId: id },
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
          (i) => i.id !== ingestSheet.id
        );
        break;
      default:
        updatedIngestSheets = prev.project.ingestSheets.filter(
          (i) => i.id !== ingestSheet.id
        );
        updatedIngestSheets = [ingestSheet, ...updatedIngestSheets];
    }

    return {
      project: {
        ...prev.project,
        ingestSheets: updatedIngestSheets,
      },
    };
  };

  if (error) return <Error error={error} />;

  return (
    <Layout>
      <div>
        <section className="section">
          <div className="container">
            {loading ? (
              <UISkeleton rows={1} />
            ) : (
              <UIBreadcrumbs
                items={[
                  {
                    label: "Projects",
                    route: "/project/list",
                  },
                  {
                    label: `${data.project.title}`,
                    route: `/project/${id}`,
                    isActive: true,
                  },
                ]}
                data-testid="project-breadcrumbs"
              />
            )}
            <>
              <div className="box">
                {loading ? (
                  <UISkeleton rows={5} />
                ) : (
                  <div className="columns" data-testid="screen-header">
                    <div className="column is-two-thirds content">
                      <h1 className="title">{data.project.title}</h1>
                      <dl>
                        <dt>Last updated</dt>
                        <dd>{formatDate(data.project.updatedAt)}</dd>
                        <dt>Total Ingest Sheets</dt>
                        <dd>{data.project.ingestSheets.length}</dd>
                      </dl>
                    </div>
                    <div className="column is-one-third">
                      <div className="buttons is-right">
                        <Link
                          to={{
                            pathname: `/project/${id}/ingest-sheet/upload`,
                            state: { projectId: id },
                          }}
                          className="button is-primary"
                          data-testid="button-new-ingest-sheet"
                        >
                          <span className="icon">
                            <FontAwesomeIcon icon="file-csv" />
                          </span>{" "}
                          <span>Add an Ingest Sheet</span>
                        </Link>
                      </div>
                    </div>
                  </div>
                )}
              </div>
              <div className="box" data-testid="screen-content">
                {loading ? (
                  <UISkeleton rows={15} />
                ) : (
                  <IngestSheetList
                    project={data.project}
                    subscribeToIngestSheetStatusChanges={() =>
                      subscribeToMore({
                        document: INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
                        variables: { projectId: id },
                        updateQuery: handleIngestSheetStatusChange,
                      })
                    }
                  />
                )}
              </div>
            </>
          </div>
        </section>
      </div>
    </Layout>
  );
};

export default ScreensProject;
