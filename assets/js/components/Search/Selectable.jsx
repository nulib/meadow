import React from "react";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";

const SearchSelectable = ({
  children,
  id,
  handleSelectItem,
  wrapsItemType = "card",
}) => {
  const field = css`
    position: absolute;
    right: ${wrapsItemType === "card" ? `0px` : `-20px`};
    top: ${wrapsItemType === "card" ? `-10px` : `-30px`};
    z-index: 10;
  `;
  const label = css`
    padding-left: 0 !important;
    &:before {
      background: #fff;
    }
  `;

  function handleChecked() {
    handleSelectItem(id);
  }

  return (
    <div className="is-relative">
      <div className="field" css={field}>
        <input
          data-testid="checkbox-search-select"
          className="is-checkradio"
          id={`search-select-${id}`}
          type="checkbox"
          name={`search-select-${id}`}
          onChange={handleChecked}
        />
        <label css={label} htmlFor={`search-select-${id}`}></label>
      </div>
      {children}
    </div>
  );
};

SearchSelectable.propTypes = {
  children: PropTypes.node,
  id: PropTypes.string,
  handleSelectItem: PropTypes.func,
  wrapsItemType: PropTypes.oneOf(["card", "list"]),
};

export default SearchSelectable;
