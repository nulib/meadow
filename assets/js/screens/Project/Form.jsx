import React from "react";
import Layout from "../Layout";
import ProjectForm from "../../components/Project/Form";

const ScreensProjectForm = ({}) => {
  const createCrumbs = () => {
    return [
      {
        title: "Projects",
        link: "/project/list"
      },
      {
        title: `Create`,
        link: `/project/create`
      }
    ];
  };
  return (
    <Layout>
      <section className="hero is-light">
        <div className="hero-body">
          <div className="container">
            <h1 className="title">Add Project</h1>
          </div>
        </div>
      </section>
      <ProjectForm />
    </Layout>
  );
};

export default ScreensProjectForm;
