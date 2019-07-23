import React from "react";
import ProjectForm from "../../components/Project/Form";
import ScreenHeader from "../../components/UI/ScreenHeader";
import ScreenContent from "../../components/UI/ScreenContent";

export default class ScreensProjectForm extends React.Component {
  render() {
    return (
      <>
        <ScreenHeader
          title="Create Ingest Project"
          description="Start a new Project by creating a name for your project"
        />
        <ScreenContent>
          <ProjectForm />
        </ScreenContent>

      </>
    );
  }
}
