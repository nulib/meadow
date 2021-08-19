import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "@js/components/Project/List";
import { GET_PROJECTS } from "@js/components/Project/project.gql.js";
import ProjectForm from "@js/components/Project/Form";
import { Button } from "@nulib/admin-react-components";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import { useQuery } from "@apollo/client";
import Error from "@js/components/UI/Error";
import { IconAdd } from "@js/components/Icon";
import {
  ActionHeadline,
  Breadcrumbs,
  FallbackErrorComponent,
  Message,
  PageTitle,
  Skeleton,
} from "@js/components/UI/UI";
import useGTM from "@js/hooks/useGTM";

const ScreensProjectList = () => {
  const [showForm, setShowForm] = useState();
  const { loadDataLayer } = useGTM();

  React.useEffect(() => {
    loadDataLayer({ pageTitle: "All Projects" });
  }, []);

  const { loading, error, data: projectsData } = useQuery(GET_PROJECTS);
  const projects = (projectsData && projectsData.projects) || [];

  const getIngestSheetsCount = (projects) => {
    return projects.reduce(
      (accumulator, current) => accumulator + current.ingestSheets.length,
      0
    );
  };

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <Breadcrumbs
            items={[{ label: "Projects", route: "/project/list" }]}
          />
          <ActionHeadline data-testid="screen-header">
            <>
              <PageTitle>Projects</PageTitle>
              <AuthDisplayAuthorized>
                <Button
                  isPrimary
                  data-testid="button-new-project"
                  onClick={() => setShowForm(!showForm)}
                >
                  <span className="icon">
                    <IconAdd />
                  </span>
                  <span>Add Project</span>
                </Button>
              </AuthDisplayAuthorized>
            </>
          </ActionHeadline>

          <Message>
            <dl>
              <dt>Total Projects</dt>
              <dd>{projects.length}</dd>
              <dt>Total Sheets Ingested</dt>
              <dd>{getIngestSheetsCount(projects)}</dd>
              {/* TODO - need to wire up total works processed count */}
            </dl>
          </Message>

          <div className="box">
            {loading && <Skeleton rows={20} />}
            {error && <Error error={error} />}

            {!loading && !error && (
              <div data-testid="screen-content">
                <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
                  <ProjectList
                    projects={projects}
                    loading={loading}
                    error={error}
                  />
                </ErrorBoundary>
              </div>
            )}
          </div>
        </div>
      </section>

      <ErrorBoundary FallbackComponent={FallbackErrorComponent}>
        <ProjectForm showForm={showForm} setShowForm={setShowForm} />
      </ErrorBoundary>
    </Layout>
  );
};

export default ScreensProjectList;
