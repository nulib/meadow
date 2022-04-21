import React from "react";
import { useParams } from "react-router";
import { useHistory } from "react-router-dom";
import Layout from "../Layout";
import IngestSheetList from "@js/components/IngestSheet/List";
import Error from "@js/components/UI/Error";
import UISkeleton from "@js/components/UI/Skeleton";
import { useQuery } from "@apollo/client";
import {
  GET_PROJECT,
  INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
} from "@js/components/Project/project.gql.js";
import { formatDate } from "@js/services/helpers";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import ProjectIngestSheetModal from "@js/components/Project/IngestSheetModal";
import { ErrorBoundary } from "react-error-boundary";
import { IconAdd, IconImages } from "@js/components/Icon";
import {
  ActionHeadline,
  Breadcrumbs,
  FallbackErrorComponent,
  Message,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";

const ScreensProject = () => {
  const history = useHistory();
  const { id } = useParams();
  const [isModalHidden, setIsModalHidden] = React.useState(true);
  const { loadDataLayer } = useGTM();
  const { handleFacetLinkClick } = useFacetLinkClick();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "Project Details" });
  }, []);

  const { loading, error, data, subscribeToMore } = useQuery(GET_PROJECT, {
    variables: { projectId: id },
  });

  const handleIngestSheetStatusChange = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const ingestSheet = subscriptionData.data.ingestSheetUpdatesForProject;

    let updatedIngestSheets;
    switch (ingestSheet.status) {
      case "UPLOADED":
        updatedIngestSheets = [
          ingestSheet,
          ...(prev.project && prev.project.ingestSheets),
        ];
        break;
      case "DELETED":
        updatedIngestSheets =
          prev.project &&
          prev.project.ingestSheets.filter((i) => i.id !== ingestSheet.id);
        break;
      default:
        updatedIngestSheets =
          prev.project &&
          prev.project.ingestSheets.filter((i) => i.id !== ingestSheet.id);
        updatedIngestSheets = [
          ingestSheet,
          ...(updatedIngestSheets ? updatedIngestSheets : ""),
        ];
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
              <Skeleton rows={1} />
            ) : (
              <Breadcrumbs
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
              <div className="">
                {loading ? (
                  <Skeleton rows={5} />
                ) : (
                  <>
                    <ActionHeadline data-testid="screen-header">
                      <PageTitle>{data.project.title}</PageTitle>
                      <AuthDisplayAuthorized>
                        <div className="buttons">
                          <Button
                            data-testid="button-new-ingest-sheet"
                            isPrimary
                            onClick={() => setIsModalHidden(!isModalHidden)}
                          >
                            <span className="icon">
                              <IconAdd />
                            </span>{" "}
                            <span>Add an Ingest Sheet</span>
                          </Button>

                          <Button
                            onClick={() =>
                              handleFacetLinkClick(
                                "IngestProject",
                                data.project.title
                              )
                            }
                            data-testid="button-view-all-works"
                          >
                            <IconImages />
                            <span>View Project Works</span>
                          </Button>
                        </div>
                      </AuthDisplayAuthorized>
                    </ActionHeadline>

                    <section className="mb-5">
                      <Message>
                        <dl>
                          <dt>Last updated</dt>
                          <dd>{formatDate(data.project.updatedAt)}</dd>
                          <dt>Total Ingest Sheets</dt>
                          <dd>{data.project.ingestSheets.length}</dd>
                          <dt>S3 Bucket Folder</dt>
                          <dd>{data.project.folder}</dd>
                        </dl>
                      </Message>
                    </section>
                  </>
                )}
              </div>
              <div className="box" data-testid="screen-content">
                {loading ? (
                  <UISkeleton rows={15} />
                ) : (
                  <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                    <IngestSheetList
                      project={data.project}
                      subscribeToIngestSheetStatusChanges={() =>
                        subscribeToMore({
                          document:
                            INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
                          variables: { projectId: id },
                          updateQuery: handleIngestSheetStatusChange,
                        })
                      }
                    />
                  </ErrorBoundary>
                )}
              </div>
            </>
          </div>
        </section>
      </div>
      <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
        <ProjectIngestSheetModal
          closeModal={() => setIsModalHidden(true)}
          isHidden={isModalHidden}
          projectId={id}
        />
      </ErrorBoundary>
    </Layout>
  );
};

export default ScreensProject;
