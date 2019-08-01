import React from "react";
import ProjectForm from "../../components/Project/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";
import Breadcrumbs from "../../components/UI/Breadcrumbs";

const ScreensProjectForm = ({}) => {
  const createCrumbs = () => {
    return [
      {
        label: "Projects",
        link: "/project/list"
      },
      {
        label: `Create`,
        link: `/project/create`
      }
    ];
  };
  return (
    <>
      <ScreenHeader
        title="Create Ingest Project"
        description="Start a new Project by creating a name for your project"
        breadCrumbs={createCrumbs()}
      />
      <ScreenContent>
        <ProjectForm />
      </ScreenContent>
    </>
  );
};

export default ScreensProjectForm;
