import React from "react";
import PropTypes from "prop-types";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import IngestSheetUpload from "./Upload";
import { useQuery } from "@apollo/react-hooks";
import { GET_PRESIGNED_URL } from "./ingestSheet.gql.js";

const IngestSheetForm = ({ project }) => {
  const { loading, error, data } = useQuery(GET_PRESIGNED_URL, {
    fetchPolicy: "no-cache",
  });

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <IngestSheetUpload project={project} presignedUrl={data.presignedUrl.url} />
  );
};

IngestSheetForm.propTypes = {
  project: PropTypes.object.isRequired,
};

export default IngestSheetForm;
