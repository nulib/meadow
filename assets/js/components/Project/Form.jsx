import React from "react";
import { withRouter } from "react-router-dom";
import gql from "graphql-tag";
import { Mutation } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { GET_PROJECTS_QUERY } from "./List";
import { toast } from "react-toastify";

const CREATE_PROJECT_MUTATION = gql`
  mutation CreateProject($projectTitle: String!) {
    createProject(title: $projectTitle) {
      id
      title
      folder
    }
  }
`;

class ProjectForm extends React.Component {
  state = {
    projectTitle: ""
  };

  handleCancel = e => {
    this.props.history.push("/project/list");
  };

  handleCompleted = title => {
    toast(`Project ${title} created successfully`);
    this.setState({ projectTitle: "" });
    this.props.history.push("/project/list");
  };

  handleTitleChange = e => {
    this.setState({ projectTitle: e.target.value });
  };

  render() {
    const { projectTitle } = this.state;
    return (
      <Mutation
        mutation={CREATE_PROJECT_MUTATION}
        variables={{
          ...this.state
        }}
        onCompleted={data => {
          this.handleCompleted(data.createProject.title);
        }}
        refetchQueries={[{ query: GET_PROJECTS_QUERY }]}
      >
        {(createProject, { loading, error }) => {
          if (loading) return <Loading />;
          return (
            <form
              onSubmit={e => {
                e.preventDefault();
                createProject();
              }}
            >
              <Error error={error} />
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
                  className="text-input"
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
          );
        }}
      </Mutation>
    );
  }
}

export default withRouter(ProjectForm);
