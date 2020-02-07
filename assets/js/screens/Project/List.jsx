import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "../../components/Project/List";
import ProjectForm from "../../components/Project/Form";

const ScreensProjectList = () => {
  const [showForm, setShowForm] = useState();

  return (
    <Layout>
      <section className="hero is-light" data-testid="screen-hero">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Projects</h1>
            <h2 className="subtitle">
              What is a project? Projects contain{" "}
              <span className="is-italic">Ingest Sheets</span>
            </h2>
            <button
              className="button is-primary"
              data-testid="button-new-project"
              onClick={() => setShowForm(!showForm)}
            >
              Add Project
            </button>
          </div>
        </div>
      </section>

      <div className="section" data-testid="screen-content">
        <div className="container">
          <ProjectList />
        </div>
      </div>

      <ProjectForm showForm={showForm} setShowForm={setShowForm} />
    </Layout>
  );
};

export default ScreensProjectList;
