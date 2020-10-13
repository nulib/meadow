import React from "react";
import PropTypes from "prop-types";
import useCachedCodeLists from "../../../hooks/useCachedCodeLists";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const displayTable = css`
  tbody td {
    width: 33%;
    word-break: break-word;
  }
`;

export default function BatchEditAboutConfirmationTable({
  items,
  type = "add",
}) {
  const [codeLists] = useCachedCodeLists();
  const marcRelators = codeLists.MARC_RELATOR;

  function getRoleLabel(roleId) {
    let foundItem = marcRelators.find((item) => item.id === roleId);
    if (!foundItem) {
      foundItem = codeLists.SUBJECT_ROLE.find((item) => item.id === roleId);
    }
    return foundItem.label || "No role label found";
  }

  const tableClass =
    type === "add"
      ? "has-background-success-light"
      : "has-background-danger-light";

  return (
    <table className={`table is-fullwidth ${tableClass}`} css={displayTable}>
      <thead>
        <tr>
          <th>Label</th>
          <th>Term</th>
          <th>Role</th>
        </tr>
      </thead>
      <tbody>
        {items.map((item) => {
          return (
            <tr key={`${item.term}-${item.label}`}>
              <td>{item.label}</td>
              <td>{item.term}</td>
              <td>{item.role && getRoleLabel(item.role.id)}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

BatchEditAboutConfirmationTable.propTypes = {
  items: PropTypes.array,
  type: PropTypes.oneOf(["add", "remove", "replace"]),
};
