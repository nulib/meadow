import React from "react";
import PropTypes from "prop-types";

/** @jsx jsx */
import { css, jsx } from "@emotion/core";
const displayTable = css`
  tbody td {
    width: 25%;
    word-break: break-word;
  }
`;

export default function BatchEditAboutConfirmationTable({
  items,
  type = "add",
}) {
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
          <th>Role Id</th>
          <th>Role Scheme</th>
        </tr>
      </thead>
      <tbody>
        {items.map((item) => {
          return (
            <tr key={`${item.term}-${item.label}`}>
              <td>{item.label}</td>
              <td>{item.term}</td>
              <td>{item.role && item.role.id}</td>
              <td>{item.role && item.role.scheme}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

BatchEditAboutConfirmationTable.propTypes = {
  items: PropTypes.array,
  type: PropTypes.oneOf(["add", "remove"]),
};
