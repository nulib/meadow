import React from "react";
import Main from "../../components/UI/Main";
import { toast } from "react-toastify";
import axios from "axios";
import { withRouter } from "react-router";

export default class ProjectForm extends React.Component {
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
      console.log("handleSubmit() error", error);
      toast(`There was an error creating the project: ${error}`);
    }
  };

  handleTitleChange = e => {
    this.setState({ projectTitle: e.target.value });
  };

  render() {
    const { projectTitle } = this.state;
    return (
      <Main>
        <h1>Create Ingest Project</h1>
        <form className="content-block" onSubmit={this.handleSubmit}>
          <div className="mb-4">
            <label
              className="block text-gray-700 text-sm font-bold mb-2"
              htmlFor="username"
            >
              Project Title
            </label>
            <input
              id="project-title"
              type="text"
              placeholder="Project Title"
              value={projectTitle}
              onChange={this.handleTitleChange}
            />
          </div>

          <div className="mt-6"></div>
          <button className="btn" type="submit">
            Submit
          </button>
          <button className="btn btn-cancel" onClick={this.handleCancel}>
            Cancel
          </button>
        </form>
      </Main>
    );
  }
}
