import React, { useState } from "react";
import { withRouter } from "react-router-dom";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { CREATE_PROJECT } from "./project.query.js";
import GetProjects from "../../gql/GetProjects.gql";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { useToasts } from "react-toast-notifications";

const ProjectForm = ({ history }) => {
  const { addToast } = useToasts();
  let inputTitle;
  const [submitDisabled, setSubmitDisabled] = useState(true);
  const [createProject, { loading, error, data }] = useMutation(
    CREATE_PROJECT,
    {
      onCompleted({ createProject }) {
        addToast(`Project ${createProject.title} created successfully`, {
          appearance: "success",
          autoDismiss: true
        });
        history.push("/project/list");
      },
      refetchQueries(mutationResult) {
        return [{ query: GetProjects }];
      }
    }
  );

  if (error) return <Error error={error} />;
  if (loading) return <Loading />;

  const handleCancel = () => {
    history.push("/project/list");
  };

  const handleInputChange = () => {
    setSubmitDisabled(inputTitle.value === "");
  };

  return (
    <div className="md:w-1/2">
      <form
        onSubmit={e => {
          e.preventDefault();
          createProject({
            variables: { projectTitle: inputTitle.value }
          });
        }}
      >
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
            ref={node => {
              inputTitle = node;
            }}
            className="text-input"
            onChange={handleInputChange}
          />
        </div>

        <UIButtonGroup>
          <UIButton type="submit" disabled={submitDisabled}>
            Submit
          </UIButton>
          <UIButton classes="btn-clear" onClick={handleCancel}>
            Cancel
          </UIButton>
        </UIButtonGroup>
      </form>
    </div>
  );
};

export default withRouter(ProjectForm);
