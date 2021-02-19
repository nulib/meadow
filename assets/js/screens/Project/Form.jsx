import React from "react";
import Layout from "../Layout";
import ProjectForm from "../../components/Project/Form";
import { ErrorBoundary } from "react-error-boundary";
import UIFallbackErrorComponent from "@js/components/UI/FallbackErrorComponent";

const ScreensProjectForm = ({}) => {
  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Add Project</h1>
          </div>
        </div>
      </section>
      <ErrorBoundary FallbackComponent={UIFallbackErrorComponent}>
        <ProjectForm />
      </ErrorBoundary>
    </Layout>
  );
};

export default ScreensProjectForm;
