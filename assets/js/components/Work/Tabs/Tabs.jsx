import React, { useState } from "react";
import WorkTabAbout from "./About";
import WorkTabStructure from "./Structure";
import WorkTabsAdministrative from "./Administrative";
import WorkTabsPreservation from "./Preservation";

const WorkTabs = ({ work }) => {
  const [activeTab, setActiveTab] = useState("tab-about");

  const handleTabClick = e => {
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
          <li className={`${activeTab === "tab-structure" && "is-active"}`}>
            <a
              id="tab-structure"
              data-testid="tab-structure"
              onClick={handleTabClick}
            >
              Structure
            </a>
          </li>
          <li className={`${activeTab === "tab-preservation" && "is-active"}`}>
            <a
              id="tab-preservation"
              data-testid="tab-preservation"
              onClick={handleTabClick}
            >
              Preservation
            </a>
          </li>
        </ul>
      </div>
      <div className="tabs-container">
        {activeTab === "tab-about" && <WorkTabAbout work={work} />}
        {activeTab === "tab-administrative" && (
          <WorkTabsAdministrative work={work} />
        )}
        {activeTab === "tab-structure" && <WorkTabStructure work={work} />}
        {activeTab === "tab-preservation" && (
          <WorkTabsPreservation work={work} />
        )}
      </div>
    </>
  );
};

export default WorkTabs;
