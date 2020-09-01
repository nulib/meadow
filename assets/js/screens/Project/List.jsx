import React, { useState } from "react";
import Layout from "../Layout";
import ProjectList from "../../components/Project/List";
import ProjectForm from "../../components/Project/Form";
// import { PrimaryButton } from "nulib-admin-ui-components";
import UIBreadcrumbs from "../../components/UI/Breadcrumbs";
import UIFormInput from "../../components/UI/Form/Input";
import UIFormField from "../../components/UI/Form/Field";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import UILevelItem from "../../components/UI/LevelItem";
import { Button } from "@nulib/admin-react-components";

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
              <div className="column is-4 has-text-right">
                <Button
                  isPrimary
                  data-testid="button-new-project"
                  onClick={() => setShowForm(!showForm)}
                >
                  Add Project
                </Button>
              </div>
            </div>
            <div className="level">
              <UILevelItem heading="Total Projects" content="XXX" />
              <UILevelItem heading="Total Sheets Ingested" content="12" />
              <UILevelItem heading="Total Works Processed" content="5,384" />
            </div>
          </div>

          <div className="box">
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
