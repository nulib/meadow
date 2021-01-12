import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "../../components/Project/List";
import ProjectForm from "../../components/Project/Form";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import UILevelItem from "../../components/UI/LevelItem";
import { Button } from "@nulib/admin-react-components";
import { DisplayAuthorized } from "@js/components/Auth/DisplayAuthorized";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";

const ScreensProjectList = () => {
  const [showForm, setShowForm] = useState();

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
              <DisplayAuthorized action="edit">
                <div className="column is-4 has-text-right">
                  <Button
                    isPrimary
                    data-testid="button-new-project"
                    onClick={() => setShowForm(!showForm)}
                  >
                    Add Project
                  </Button>
                </div>
              </DisplayAuthorized>
            </div>
            <div className="level">
              <UILevelItem heading="Total Projects" content="XXX" />
              <UILevelItem heading="Total Sheets Ingested" content="12" />
              <UILevelItem heading="Total Works Processed" content="5,384" />
            </div>
          </div>

          <div className="box">
            <div data-testid="screen-content">
              <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
                <ProjectList />
              </ErrorBoundary>
            </div>
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
