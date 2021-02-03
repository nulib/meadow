import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

function HomeIngestBox({ handleAddWork }) {
  return (
    <div className="buttons">
      {/* <div className="is-flex mb-4 is-align-items-center">
        <FontAwesomeIcon icon="file-import" size="4x" />
        <h2 className="subtitle is-3 pl-3">Ingest Objects</h2>
      </div>

      <div className="buttons is-centered">
        <Link className="button" to="/project/list">
          View Projects
        </Link>
        <AuthDisplayAuthorized action="edit">
          <Button data-testid="add-work-button" onClick={handleAddWork}>
            Add Work
          </Button>
        </AuthDisplayAuthorized>
      </div> */}
      <Link className="button is-large is-fullwidth" to="/project/list">
        <span className="icon">
          <FontAwesomeIcon icon="project-diagram" />
        </span>
        <span>View Projects</span>
      </Link>
      <AuthDisplayAuthorized action="edit">
        <Button
          data-testid="add-work-button"
          onClick={handleAddWork}
          className="is-large is-fullwidth"
        >
          <span className="icon">
            <FontAwesomeIcon icon="plus" />
          </span>
          <span>Add Work</span>
        </Button>
      </AuthDisplayAuthorized>
    </div>
  );
}

HomeIngestBox.propTypes = {
  handleAddWork: PropTypes.func,
};

export default HomeIngestBox;
