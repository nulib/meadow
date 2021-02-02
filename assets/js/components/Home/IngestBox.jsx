import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

function HomeIngestBox({ handleAddWork }) {
  return (
    <>
      <FontAwesomeIcon icon="file-import" size="4x" />
      <h2 className="subtitle is-4 pt-3">Ingest Objects</h2>
      <div className="buttons is-centered">
        <Link className="button is-fullwidth" to="/project/list">
          View Projects
        </Link>
        <AuthDisplayAuthorized action="edit">
          <Button
            data-testid="add-work-button"
            onClick={handleAddWork}
            className="is-fullwidth"
          >
            Add Work
          </Button>
        </AuthDisplayAuthorized>
      </div>
    </>
  );
}

HomeIngestBox.propTypes = {
  handleAddWork: PropTypes.func,
};

export default HomeIngestBox;
