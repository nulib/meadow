import React from "react";
import PropTypes from "prop-types";
import { Link, useHistory } from "react-router-dom";
import { IconAdd, IconProjects, IconSearch } from "@js/components/Icon";
import { Button } from "@nulib/design-system";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const container = css`
  display: flex;
  justify-content: space-evenly;
  padding-top: 2rem;
`;

function CalloutActionsRow({ handleAddWork }) {
  const history = useHistory();

  function handleSearchClick() {
    history.push("/search");
  }

  function handleViewProjects() {
    history.push("/project/list");
  }

  return (
    <section css={container}>
      <Button isPrimary onClick={handleSearchClick}>
        <IconSearch />
        <span>Search &amp; describe objects</span>
      </Button>

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

CalloutActionsRow.propTypes = {
  handleAddWork: PropTypes.func,
};

export default CalloutActionsRow;
