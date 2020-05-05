import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "../../components/Project/List";
import ProjectForm from "../../components/Project/Form";
// import { PrimaryButton } from "nulib-admin-ui-components";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import UIFormInput from "../../components/UI/Form/Input";
import UIFormField from "../../components/UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";

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
                {/* <PrimaryButton
                  data-testid="button-new-project"
                  onClick={() => setShowForm(!showForm)}
                >
                  Add Project
                </PrimaryButton> */}
              </div>
            </div>
            <UIFormField childClass="has-icons-left">
              <UIFormInput
                placeholder="Search projects"
                name="projectsSearch"
                label="Filter projects"
              />
              <span className="icon is-small is-left">
                <FontAwesomeIcon icon="search" />
              </span>
            </UIFormField>
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
