import React from "react";
import PropTypes from "prop-types";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { Button } from "@nulib/admin-react-components";
import { Link } from "react-router-dom";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import IconProjects from "@js/components/Icon/Projects";
import IconAdd from "@js/components/Icon/Add";

function HomeIngestBox({ handleAddWork }) {
  return (
    <AuthDisplayAuthorized>
      <div className="buttons">
        <Link className="button is-large is-fullwidth" to="/project/list">
          <IconProjects className="icon" />
          <span>View Projects</span>
        </Link>
        <Button
          data-testid="add-work-button"
          onClick={handleAddWork}
          className="is-large is-fullwidth"
        >
          <IconAdd className="icon" />
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
