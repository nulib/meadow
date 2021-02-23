import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

function HomeIngestBox({ handleAddWork }) {
  return (
    <AuthDisplayAuthorized>
      <div className="buttons">
        <Link className="button is-large is-fullwidth" to="/project/list">
          <span className="icon">
            <FontAwesomeIcon icon="project-diagram" />
          </span>
          <span>View Projects</span>
        </Link>
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
      </div>
    </AuthDisplayAuthorized>
  );
}

HomeIngestBox.propTypes = {
  handleAddWork: PropTypes.func,
};

export default HomeIngestBox;
