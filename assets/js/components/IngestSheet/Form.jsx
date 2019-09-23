import React from "react";
import PropTypes from "prop-types";
import { withRouter } from "react-router-dom";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import UploadIngestSheet from "./Upload";
import { useQuery } from "@apollo/react-hooks";
import { GET_PRESIGNED_URL } from "./ingestSheet.query.js";

const IngestSheetForm = ({ history, projectId }) => {
  const {
    loading,
    error,
    data: { presignedUrl }
  } = useQuery(GET_PRESIGNED_URL);

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <div className="md:w-1/2">
      <UploadIngestSheet
        history={history}
        projectId={projectId}
        presignedUrl={presignedUrl.url}
      />
    </div>
  );
};

IngestSheetForm.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired
};

export default withRouter(IngestSheetForm);
