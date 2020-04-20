import React, { useState } from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";

const Work = ({ work }) => {
  return (
    <div data-testid="work-component">
      <div data-testid="viewer" className="box">
        <OpenSeadragonViewer manifestUrl={work.manifestUrl} />
      </div>
      <div className="box">
        <WorkTabs work={work} />
      </div>
    </div>
  );
};

export default Work;
