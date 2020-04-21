import React, { useState } from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";

const Work = ({ work }) => {
  return (
    <section className="section" data-testid="work-component">
      <div data-testid="viewer">
        <OpenSeadragonViewer manifestUrl={work.manifestUrl} />
      </div>
      <div className="container">
        <div className="box">
          <WorkTabs work={work} />
        </div>
      </div>
    </section>
  );
};

export default Work;
