import React, { useState } from "react";
import axios from "axios";
import gql from "graphql-tag";
import PropTypes from "prop-types";
import { Mutation } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { withRouter } from "react-router-dom";
import { GET_PROJECT_QUERY } from "../../screens/Project/Project";
import { toast } from 'react-toastify';

const CREATE_INGEST_JOB_MUTATION = gql`
  mutation CreateIngestJob(
    $name: String!
    $projectId: String!
    $filename: String!
  ) {
    createIngestJob(name: $name, project_id: $projectId, filename: $filename) {
      id
      name
      project {
        id
        title
      }
      filename
    }
  }
`;

const UploadInventorySheet = ({ projectId, presignedUrl, history }) => {
  const [values, setValues] = useState({ ingest_job_name: "", file: "" });

  const handleInputChange = event => {
    event.persist();
    const { name, value } = event.target;
    setValues({ ...values, [name]: value });
  };

  const handleCancel = e => {
    history.push(`/project/${projectId}`);
  };

  const uploadToS3 = () => {
    try {
      const submitFile = async (data, headers) => {
        await axios.put(presignedUrl, data, { headers: headers });
      };

      const file = document.getElementById("file").files[0];
      const reader = new FileReader();
      reader.onload = event => {
        const headers = { "Content-Type": file.type };
        submitFile(event.target.result, headers);
      };
      reader.readAsText(file);
    } catch (error) {
      console.log(error);
      toast(`Error uploading file to S3: ${error}`);
    }
  };

  const { ingest_job_name, file } = values;

  return (
    <Mutation
      mutation={CREATE_INGEST_JOB_MUTATION}
      variables={{
        name: ingest_job_name,
        projectId: projectId,
        filename: `s3://${presignedUrl
          .split("?")[0]
          .split("/")
          .slice(-3)
          .join("/")}`
      }}
      onCompleted={(data) => {
        history.push(`/project/${projectId}/inventory-sheet/${data.createIngestJob.id}`);
      }}
      refetchQueries={[
        {
          query: GET_PROJECT_QUERY,
          variables: { projectId: projectId }
        }
      ]}
    >
      {(createIngestJob, { data, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;

        return (
          <form
            className="content-block"
            onSubmit={e => {
              e.preventDefault();
              uploadToS3();
              createIngestJob();            
          }}
          >
            <Error error={error} />
            <div className="mb-4">
              <label htmlFor="ingest_job_name">Ingest Job Name</label>
              <input
                id={"ingest_job_name"}
                name="ingest_job_name"
                type="text"
                onChange={handleInputChange}
              />
            </div>
            <div className="mb-4">
              <label htmlFor="file">Inventory Sheet File</label>
              <input
                id={"file"}
                name="file"
                type="file"
                onChange={handleInputChange}
              />
            </div>
            <div className="mt-6"></div>
            <button className="btn" type="submit">
              Submit
            </button>
            <button className="btn btn-cancel" onClick={handleCancel}>
              Cancel
            </button>
          </form>
        );
      }}
    </Mutation>
  );
};

UploadInventorySheet.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired,
  presignedUrl: PropTypes.string.isRequired
};

export default withRouter(UploadInventorySheet);
