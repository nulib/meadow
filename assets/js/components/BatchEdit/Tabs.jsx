import React, { useState } from "react";

export default function BatchEditTabs() {
  const [activeTab, setActiveTab] = useState("tab-about");

  const handleTabClick = (e) => {
    setActiveTab(e.target.id);
  };

  return (
    <>
      <div className="tabs is-centered is-boxed" data-testid="tabs">
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
          <p>content here</p>
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
