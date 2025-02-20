import React from "react";

import { IconSort, IconSortDown, IconSortUp } from "@js/components/Icon";

const UIOrderBy = ({ columnName, label, orderedFileSets, onClickCallback }) => {
  const { order, orderBy } = orderedFileSets;

  const handleOrderClick = () => {
    onClickCallback({
      order: orderBy === columnName && order === "asc" ? "desc" : "asc",
      orderBy: columnName,
    });
  };

  const isActive = orderBy === columnName;

  return (
    <a
      className="ml-2"
      onClick={handleOrderClick}
      role="link"
      style={{
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        justifyContent: "flex-start",
        gap: "0.5rem",
        whiteSpace: "nowrap",
        fontWeight: isActive ? "700" : "400",
      }}
    >
      {label}
      {isActive ? (
        order === "asc" ? (
          <IconSortDown data-sort="asc" />
        ) : (
          <IconSortUp data-sort="desc" />
        )
      ) : (
        <span
          style={{
            color: "var(--colors-richBlack20)",
            display: "inline-flex",
            alignItems: "center",
          }}
        >
          <IconSort data-sort="" />
        </span>
      )}
    </a>
  );
};

export default UIOrderBy;
