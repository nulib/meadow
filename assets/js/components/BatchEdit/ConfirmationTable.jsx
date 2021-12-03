import React from "react";
import PropTypes from "prop-types";
import { getMetadataLabel } from "@js/services/metadata";

/** @jsx jsx */
import { css, jsx } from "@emotion/react";
const displayTable = css`
  tbody td {
    word-break: break-word;
    &:nth-of-type(1) {
      width: 5%;
    }
    &:nth-of-type(2) {
      width: 20%;
    }
  }
`;

export default function BatchEditConfirmationTable({
  codeLists,
  itemsObj,
  type = "add",
}) {
  if (
    !codeLists.marcData ||
    !codeLists.notesData ||
    !codeLists.relatedUrlData ||
    !codeLists.subjectRoleData
  )
    return null;

  const marcRelators = codeLists.marcData.codeList || [];
  const notes = codeLists.notesData.codeList || [];
  const relatedUrls = codeLists.relatedUrlData.codeList || [];

  function getRoleLabel(roleId) {
    let foundItem = marcRelators.find((item) => item.id === roleId);
    if (!foundItem) {
      foundItem = codeLists.subjectRoleData.codeList.find(
        (item) => item.id === roleId
      );
    }
    return foundItem?.label || "No role label found";
  }

  function getNotesLabel(note) {
    let foundItem = notes.find((item) => item.id === note);
    return foundItem.label || "No Notes label found";
  }

  function getUrlLabel(url) {
    let foundItem = relatedUrls.find((item) => item.id === url);
    return foundItem.label || "No URL label found";
  }

  return (
    <table
      className={`table is-fullwidth`}
      css={displayTable}
      data-testid="confirmation-table"
    >
      <thead>
        <tr>
          <th>Metadata Field</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        {Object.keys(itemsObj).map((key) => {
          let items = itemsObj[key];

          // Make it easier to loop by making non-Array items (like Title or Description)
          // a single value array
          if (!Array.isArray(items)) {
            items = [items];
          }

          // Account for "remove all" replaces which have a value of an empty array
          // (An empty array means all values are replaced with no value)
          if (type === "replace" && items.length === 0) {
            return (
              <tr key={key}>
                <td className="is-capitalized">{getMetadataLabel(key)}</td>
                <td className="is-italic">* all values will be removed</td>
              </tr>
            );
          }

          return items.map((item) => {
            let value = item;
            let rowKey = item;

            // Account for controlled term field values
            if (typeof item === "object" && item.term) {
              rowKey = `${item.term}-${item.label}`;
              value = `${item.label} | ${item.term} | ${
                item.role && getRoleLabel(item.role.id)
              }`;
            }

            // Notes.
            if (typeof item === "object" && item.note) {
              rowKey = item.note;
              value = `${item.note} | ${
                item.type && getNotesLabel(item.type.id)
              }`;
            }

            // Related URL.  TODO: Could find a better way to cue on this than "url"
            if (typeof item === "object" && item.url) {
              rowKey = item.url;
              value = `${item.url} | ${
                item.label && getUrlLabel(item.label.id)
              }`;
            }

            // Account for Coded term field values
            if (typeof item === "object" && item.scheme) {
              rowKey = `${item.id}`;
              value = `${item.label}`;
            }

            return (
              <tr key={rowKey}>
                <td className="is-capitalized">{getMetadataLabel(key)}</td>
                <td>{value}</td>
              </tr>
            );
          });
        })}
      </tbody>
    </table>
  );
}

BatchEditConfirmationTable.propTypes = {
  itemsObj: PropTypes.object,
  type: PropTypes.oneOf(["add", "remove", "replace"]),
};
