import React from "react";
import UIFormField from "../UI/Form/Field";
import PropTypes from "prop-types";
import { splitFacetKey } from "../../services/metadata";
import { useBatchDispatch } from "../../context/batch-edit-context";
import { Button } from "@nulib/design-system";
import { IconDelete, IconMinus } from "@js/components/Icon";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const listItem = css`
  display: flex;
  align-items: center;
  border-bottom: 2px solid white;
  padding: 10px 0;
  justify-content: space-between;
`;

export default function BatchEditRemove({
  handleRemoveClick,
  label,
  name,
  removeItems,
}) {
  const dispatch = useBatchDispatch();

  const removeFromDelete = (e, item) => {
    e.preventDefault();
    dispatch({
      type: "updateRemoveItem",
      fieldName: name,
      key: item,
    });
  };
  return (
    <div data-testid="batch-edit-remove">
      <UIFormField>
        <Button
          data-testid="button-remove"
          isLight
          onClick={() => handleRemoveClick({ label, name })}
        >
          <IconMinus />
          <span>View and remove {label}</span>
        </Button>
      </UIFormField>

      {removeItems.length > 0 && (
        <div className="content has-background-danger-light">
          <ul className="ml-4">
            {removeItems.map((item) => {
              const { label, role, term } = splitFacetKey(item);
              return (
                <li key={item} css={listItem}>
                  {`${label} - ${term}`}
                  <span
                    className="is-pulled-right icon mr-2 is-clickable"
                    onClick={(e) => removeFromDelete(e, item)}
                    data-testid="remove-delete-entries"
                  >
                    <IconDelete />
                  </span>
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}

BatchEditRemove.propTypes = {
  handleRemoveClick: PropTypes.func,
  label: PropTypes.string,
  name: PropTypes.string,
  removeItems: PropTypes.array,
};
