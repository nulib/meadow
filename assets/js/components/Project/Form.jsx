import React from "react";
import { toast } from "react-toastify";
import axios from "axios";
import ButtonGroup from "../UI/ButtonGroup";
import UIForm from "../UI/Form/Form";
import UIInput from "../UI/Form/Input";
import UIButton from "../UI/Button";
import { withRouter } from "react-router-dom";

class ProjectForm extends React.Component {
  state = {
    projectTitle: ""
  };

  handleCancel = e => {
    this.props.history.push("/project/list");
  };

  handleSubmit = async e => {
    e.preventDefault();
    const { projectTitle } = this.state;

    try {
      await axios.post("/api/v1/projects", {
        project: {
          title: projectTitle
        }
      });

      // Display success notification and redirect to All Projects view
      toast(`${projectTitle} created successfully`);
      this.props.history.push("/project/list");
    } catch (error) {
      if (error.response) {
        console.log(`Error Status Code: ${error.response.status}`);
        console.log(
          `Error creating project: ${JSON.stringify(
            error.response.data.errors
          )}`
        );
        toast(
          `Status Code: ${
            error.response.status
          } error creating project: ${JSON.stringify(
            error.response.data.errors
          )}`
        );
      } else {
        console.log(error);
        toast(`Error: ${error}`);
      }
    }
  };

  handleTitleChange = e => {
    this.setState({ projectTitle: e.target.value });
  };

  render() {
    const { projectTitle } = this.state;
    return (
      <UIForm testId="project-form" onSubmit={this.handleSubmit}>
        <UIInput
          label="Project Title"
          name="project-title"
          id="project-title"
          onChange={this.handleTitleChange}
        />

        <ButtonGroup>
          <UIButton type="submit" label="Submit" disabled={!projectTitle} />
          <UIButton
            label="Cancel"
            classes="btn-cancel"
            onClick={this.handleCancel}
          />
        </ButtonGroup>
      </UIForm>
    );
  }
}

export default withRouter(ProjectForm);
