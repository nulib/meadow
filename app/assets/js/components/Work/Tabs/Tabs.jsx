import React, { useState } from "react";
import WorkTabAbout from "@js/components/Work/Tabs/About";
import WorkTabStructure from "@js/components/Work/Tabs/Structure/Structure";
import WorkTabsAdministrative from "@js/components/Work/Tabs/Administrative/Administrative";
import WorkTabsPreservation from "@js/components/Work/Tabs/Preservation/Preservation";
import WorkTabsAutoEdit from "@js/components/Work/Tabs/AutoEdit";
import { IIIFProvider } from "@js/components/IIIF/IIIFProvider";
import { CodeListProvider } from "@js/context/code-list-context";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconMagic } from "@js/components/Icon";

const WorkTabs = ({ work }) => {
  const [activeTab, setActiveTab] = useState("tab-about");
  const handleTabClick = (e) => {
    setActiveTab(e.currentTarget.id);
  };

  if (!work) {
    return null;
  }

  return (
    <CodeListProvider>
      <IIIFProvider>
        <div className="tabs" data-testid="tabs">
          <ul className="is-flex is-justify-content-space-between is-align-items-center">
            <div className="is-flex">
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
                  Access files
                </a>
              </li>
              <AuthDisplayAuthorized>
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
              </AuthDisplayAuthorized>
            </div>
            <AuthDisplayAuthorized>
              <li className={`${activeTab === "tab-auto-edit" && "is-active"}`}>
                <a
                  id="tab-auto-edit"
                  data-testid="tab-auto-edit"
                  onClick={handleTabClick}
                  className="is-flex is-align-items-center"
                  style={{ gap: "0.5rem" }}
                >
                  <IconMagic /> <span>Auto Edit</span>
                </a>
              </li>
            </AuthDisplayAuthorized>
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
          <AuthDisplayAuthorized>
            <div
              data-testid="tab-preservation-content"
              className={`${
                activeTab !== "tab-preservation" ? "is-hidden" : ""
              }`}
            >
              <WorkTabsPreservation work={work} />
            </div>
          </AuthDisplayAuthorized>
          <AuthDisplayAuthorized>
            <div
              data-testid="tab-auto-edit-content"
              className={`${activeTab !== "tab-auto-edit" ? "is-hidden" : ""}`}
            >
              <WorkTabsAutoEdit work={work} />
            </div>
          </AuthDisplayAuthorized>
        </div>
      </IIIFProvider>
    </CodeListProvider>
  );
};

export default WorkTabs;
