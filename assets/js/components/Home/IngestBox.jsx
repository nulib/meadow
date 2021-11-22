import React from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { IconAdd, IconProjects } from "@js/components/Icon";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";

function HomeIngestBox({ handleAddWork }) {
  const history = useHistory();

  function handleViewProjects() {
    history.push("/project/list");
  }

  return (
    <section
      css={{ display: "flex", flexDirection: "column", marginBottom: "1rem" }}
    >
      <AuthDisplayAuthorized>
        <Button onClick={handleViewProjects}>
          <IconProjects className="icon" />
          <span>View Projects</span>
        </Button>
        <Button
          data-testid="add-work-button"
          onClick={handleAddWork}
          className="is-large is-fullwidth"
        >
          <IconAdd className="icon" />
          <span>Add Work</span>
        </Button>
      </AuthDisplayAuthorized>
    </section>
  );
}

HomeIngestBox.propTypes = {
  handleAddWork: PropTypes.func,
};

export default HomeIngestBox;
