import React from "react";

const UIHeaderGlobalSearch = ({ currentUser }) => (
  <div className="">
    <div className="">
      <input
        data-testid="global-search"
        type="text"
        placeholder="Search for items"
        className=""
      />
      <div className="">Search icon here</div>
    </div>
  </div>
);

export default UIHeaderGlobalSearch;
