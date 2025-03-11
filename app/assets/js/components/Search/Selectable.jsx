import React from "react";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconCheckAlt } from "../Icon";

const SearchSelectable = ({ children, id, handleSelectItem, isSelected }) => {
  const wrapper = css`
    background: ${isSelected
      ? "linear-gradient(0deg, var(--colors-nuPurple30), var(--colors-nuPurple10))"
      : "transparent"};
    padding: 0.5em;
    border-radius: 0.5em;
    margin-bottom: 0.5em;
  `;

  const flex = css`
    display: flex;
    align-items: flex-end;
    justify-content: flex-end;
  `;

  const button = css`
    svg {
      color: ${isSelected ? "#fff !important" : "transparent"};
    }

    &:hover,
    &:focus {
      svg {
        color: var(--colors-richBlack10);
      }
    }
  `;

  const buttonClasses = `button is-small ${isSelected ? "is-primary" : ""} mb-2`;

  const handleOnClick = (e) => {
    e.preventDefault();
    e.stopPropagation();
    e.currentTarget.blur();
    handleSelectItem(id);
  };

  return (
    <div className="is-relative" css={wrapper}>
      <AuthDisplayAuthorized>
        <div css={flex}>
          <button
            aria-label={isSelected ? "Deselect work" : "Select work"}
            aria-checked={isSelected}
            className={buttonClasses}
            css={button}
            data-testid="checkbox-search-select"
            id={`search-select-${id}`}
            name={`search-select-${id}`}
            onClick={handleOnClick}
            role="checkbox"
          >
            <IconCheckAlt size="15px" />
          </button>
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
};

export default SearchSelectable;
