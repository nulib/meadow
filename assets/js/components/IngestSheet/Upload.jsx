import React, { useState } from "react";
import axios from "axios";
import PropTypes from "prop-types";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import { withRouter } from "react-router-dom";
import { GET_PROJECT } from "../../screens/Project/Project";
import { toast } from "react-toastify";
import { useMutation } from "@apollo/react-hooks";
import UIButton from "../UI/Button";
import UIButtonGroup from "../UI/ButtonGroup";
import { CREATE_INGEST_SHEET } from "./ingestSheet.query";

const UploadIngestSheet = ({ projectId, presignedUrl, history }) => {
  const [values, setValues] = useState({ ingest_sheet_name: "", file: "" });
  const [createIngestSheet, { data, loading, error }] = useMutation(
    CREATE_INGEST_SHEET,
    {
      onCompleted({ createIngestSheet }) {
        history.push(
          `/project/${projectId}/ingest-sheet/${createIngestSheet.id}`
        );
      },
      refetchQueries(mutationResult) {
        return [
          {
            query: GET_PROJECT,
            variables: { projectId: projectId }
          }
        ];
      }
    }
  );

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
      toast(`Error uploading file to S3: ${error}`, { type: "error" });
    }
  };

  const { ingest_sheet_name, file } = values;

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <form
      onSubmit={e => {
        e.preventDefault();
        uploadToS3();
        createIngestSheet({
          variables: {
            name: ingest_sheet_name,
            projectId: projectId,
            filename: `s3://${presignedUrl
              .split("?")[0]
              .split("/")
              .slice(-3)
              .join("/")}`
          }
        });
      }}
    >
      <Error error={error} />
      <div className="mb-4">
        <label htmlFor="ingest_sheet_name">Ingest Sheet Name</label>
        <input
          id={"ingest_sheet_name"}
          name="ingest_sheet_name"
          type="text"
          className="text-input"
          onChange={handleInputChange}
        />
      </div>
      <div className="mb-4">
        <label htmlFor="file">Ingest Sheet File</label>
        <input
          id={"file"}
          name="file"
          type="file"
          onChange={handleInputChange}
        />
      </div>
      <UIButtonGroup>
        <UIButton type="submit">Submit</UIButton>
        <UIButton classes="btn-clear" onClick={handleCancel}>
          Cancel
        </UIButton>
      </UIButtonGroup>
    </form>
  );
};

UploadIngestSheet.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired,
  presignedUrl: PropTypes.string.isRequired
};

export default withRouter(UploadIngestSheet);
