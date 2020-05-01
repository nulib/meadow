import React, { useState } from "react";
import WorkTabAbout from "./About";
import WorkTabStructure from "./Structure";
import WorkTabsAdministrative from "./Administrative";
import WorkTabsPreservation from "./Preservation";
import { IIIFProvider } from "../../IIIF/IIIFProvider";

const WorkTabs = ({ work }) => {
  const [activeTab, setActiveTab] = useState("tab-about");

  const handleTabClick = (e) => {
    setActiveTab(e.target.id);
  };

  return (
    <>
      <IIIFProvider>
        <div className="tabs is-centered is-boxed" data-testid="tabs">
          <ul>
            <li className={`${activeTab === "tab-about" && "is-active"}`}>
              <a
                id="tab-about"
                data-testid="tab-about"
                onClick={handleTabClick}
              >
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
            <li
              className={`${activeTab === "tab-preservation" && "is-active"}`}
            >
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
          <div
            data-testid="tab-about-content"
            className={`${activeTab !== "tab-about" ? "is-hidden" : ""}`}
          >
            <WorkTabAbout work={work} />
          </div>
          <div
            data-testid="tab-administrative-content"
            className={`${
              activeTab !== "tab-administrative" ? "is-hidden" : ""
            }`}
          >
            <WorkTabsAdministrative work={work} />
          </div>
          <div
            data-testid="tab-structure-content"
            className={`${activeTab !== "tab-structure" ? "is-hidden" : ""}`}
          >
            <WorkTabStructure work={work} />
          </div>
          <div
            data-testid="tab-preservation-content"
            className={`${activeTab !== "tab-preservation" ? "is-hidden" : ""}`}
          >
            <WorkTabsPreservation work={work} />
          </div>
        </div>
      </IIIFProvider>
    </>
  );
};

export default WorkTabs;
