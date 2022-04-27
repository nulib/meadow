import React from "react";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";

const SearchSelectable = ({
  children,
  id,
  handleSelectItem,
  isSelected,
  wrapsItemType = "card",
}) => {
  const field = css`
    position: absolute;
    right: ${wrapsItemType === "card" ? `0px` : `-20px`};
    top: ${wrapsItemType === "card" ? `-10px` : `-30px`};
    z-index: 10;
  `;
  const label = css`
    &:before {
      background: #fff;
    }
  `;

  function handleChecked() {
    handleSelectItem(id);
  }

  return (
    <div className="is-relative">
      <AuthDisplayAuthorized>
        <div className="field" css={field}>
          <input
            data-testid="checkbox-search-select"
            checked={isSelected}
            className="is-checkradio"
            id={`search-select-${id}`}
            type="checkbox"
            name={`search-select-${id}`}
            onChange={handleChecked}
          />
          <label
            className="pl-0"
            css={label}
            htmlFor={`search-select-${id}`}
          ></label>
        </div>
      </AuthDisplayAuthorized>
      {children}
    </div>
  );
};

SearchSelectable.propTypes = {
  children: PropTypes.node,
  id: PropTypes.string,
  handleSelectItem: PropTypes.func,
  isSelected: PropTypes.bool,
  wrapsItemType: PropTypes.oneOf(["card", "list"]),
};

export default SearchSelectable;
