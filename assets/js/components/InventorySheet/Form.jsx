import React from "react";
import PropTypes from "prop-types";
import { withRouter } from "react-router-dom";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import UploadInventorySheet from "./Upload";
import { useQuery } from "@apollo/react-hooks";
import { GET_PRESIGNED_URL } from "./inventorySheet.query.js";

const InventorySheetForm = ({ history, projectId }) => {
  const {
    loading,
    error,
    data: { presignedUrl }
  } = useQuery(GET_PRESIGNED_URL);

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <UploadInventorySheet
      history={history}
      projectId={projectId}
      presignedUrl={presignedUrl.url}
    />
  );
};

InventorySheetForm.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired
};

export default withRouter(InventorySheetForm);
