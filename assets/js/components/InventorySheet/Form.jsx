import React from "react";
import PropTypes from "prop-types";
import { withRouter } from "react-router-dom";
import gql from "graphql-tag";
import { Query } from "react-apollo";
import Error from "../../screens/Error";
import Loading from "../../screens/Loading";
import UploadInventorySheet from "./Upload";

const GET_PRESIGNED_URL = gql`
  query {
  presignedUrl {
    url
  }
}
`;

const InventorySheetForm = ({ history, projectId }) => {

  return (
    <Query query={GET_PRESIGNED_URL}>
      {({ data: { presignedUrl }, loading, error }) => {
        if (loading) return <Loading />;
        if (error) return <Error error={error} />;
        return (
          <UploadInventorySheet history={history} projectId={projectId} presignedUrl={presignedUrl.url} />
        );
      }}
    </Query>
  )
};

InventorySheetForm.propTypes = {
  history: PropTypes.shape({
    push: PropTypes.func.isRequired
  }).isRequired,
  projectId: PropTypes.string.isRequired
};

export default withRouter(InventorySheetForm);
