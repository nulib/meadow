import React, { useState } from "react";
import BatchEditAbout from "./About/About";
import PropTypes from "prop-types";

export default function BatchEditTabs({ numberOfResults }) {
  const [activeTab, setActiveTab] = useState("tab-about");

  const handleTabClick = (e) => {
    setActiveTab(e.target.id);
  };

  return (
    <>
      <div className="tabs is-centered is-boxed" data-testid="batch-edit-tabs">
        <ul>
          <li className={`${activeTab === "tab-about" && "is-active"}`}>
            <a id="tab-about" data-testid="tab-about" onClick={handleTabClick}>
              About this item
            </a>
          </li>
          <li
            className={`${activeTab === "tab-administrative" && "is-active"}`}
          >
            <a
              id="tab-administrative"
              data-testid="tab-administrative"
              onClick={handleTabClick}
            >
              Administrative
            </a>
          </li>
        </ul>
      </div>
      <div className="tabs-container">
        <div
          data-testid="tab-about-content"
          className={`${activeTab !== "tab-about" ? "is-hidden" : ""}`}
        >
          <BatchEditAbout numberOfResults={numberOfResults} />
        </div>
        <div
          data-testid="tab-administrative-content"
          className={`${activeTab !== "tab-administrative" ? "is-hidden" : ""}`}
        >
          <p>administrative content here</p>
        </div>
      </div>
    </>
  );
}

BatchEditTabs.propTypes = {
  numberOfResults: PropTypes.number,
};
