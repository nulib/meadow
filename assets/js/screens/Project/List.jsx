import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "@js/components/Project/List";
import { GET_PROJECTS } from "@js/components/Project/project.gql.js";
import ProjectForm from "@js/components/Project/Form";
import UIBreadcrumbs from "@js/components/UI/Breadcrumbs";
import UILevelItem from "@js/components/UI/LevelItem";
import { Button } from "@nulib/admin-react-components";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";
import { useQuery } from "@apollo/client";
import UISkeleton from "@js/components/UI/Skeleton";
import Error from "@js/components/UI/Error";

const ScreensProjectList = () => {
  const [showForm, setShowForm] = useState();
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
          <UIBreadcrumbs
            items={[{ label: "Projects", route: "/project/list" }]}
          />
          <div className="box">
            <div className="columns" data-testid="screen-header">
              <div className="column is-8">
                <h1 className="title">Projects</h1>
                <p>
                  Projects are a way to organize{" "}
                  <span className="is-italic">Ingest Sheets</span>.{" "}
                </p>
              </div>
              <AuthDisplayAuthorized action="edit">
                <div className="column is-4 has-text-right">
                  <Button
                    isPrimary
                    data-testid="button-new-project"
                    onClick={() => setShowForm(!showForm)}
                  >
                    Add Project
                  </Button>
                </div>
              </AuthDisplayAuthorized>
            </div>
            <div className="level">
              <UILevelItem
                heading="Total Projects"
                content={`${projects.length}`}
              />
              <UILevelItem
                heading="Total Sheets Ingested"
                content={`${getIngestSheetsCount(projects)}`}
              />
              {/* TODO - need to wire up total works processed count */}
              {/* <UILevelItem heading="Total Works Processed" content="5,384" /> */}
            </div>
          </div>

          <div className="box">
            {loading && <UISkeleton rows={20} />}
            {error && <Error error={error} />}

            {!loading && !error && (
              <div data-testid="screen-content">
                <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
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

      <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
        <ProjectForm showForm={showForm} setShowForm={setShowForm} />
      </ErrorBoundary>
    </Layout>
  );
};

export default ScreensProjectList;
