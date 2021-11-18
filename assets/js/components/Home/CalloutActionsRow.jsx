import React from "react";
import PropTypes from "prop-types";
import { useHistory } from "react-router-dom";
import { IconSearch } from "@js/components/Icon";
import { Button } from "@nulib/design-system";

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
  return (
    <section css={container}>
      <Button isPrimary onClick={handleSearchClick}>
        <IconSearch />
        <span>Search &amp; describe objects</span>
      </Button>
    </section>
  );
}

CalloutActionsRow.propTypes = {
  handleAddWork: PropTypes.func,
};

export default CalloutActionsRow;
