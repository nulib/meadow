import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "../../components/Project/List";
import ProjectForm from "../../components/Project/Form";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import Breadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensProjectList = () => {
  const [showForm, setShowForm] = useState();

  return (
    <Layout>
      <section className="section">
        <div className="container">
          <Breadcrumbs
            items={[{ label: "Projects", route: "/project/list" }]}
          />
          <div className="box">
            <div className="columns" data-testid="screen-header">
              <div className="column is-8">
                <h1 className="title">Projects</h1>
                <h2 className="subtitle">
                  Projects contain{" "}
                  <span className="is-italic">Ingest Sheets</span>
                </h2>
              </div>
              <div className="column is-4 has-text-right">
                <button
                  className="button is-primary"
                  data-testid="button-new-project"
                  onClick={() => setShowForm(!showForm)}
                >
                  Add Project
                </button>
              </div>
            </div>
            <div className="field">
              <input
                className="input"
                type="text"
                placeholder="Search projects"
              />
            </div>
            <div data-testid="screen-content">
              <ProjectList />
            </div>
          </div>
        </div>
      </section>

      <ProjectForm showForm={showForm} setShowForm={setShowForm} />
    </Layout>
  );
};

export default ScreensProjectList;
