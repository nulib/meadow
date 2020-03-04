import React, { useState } from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";

const Work = ({ work }) => {
  return (
    <div data-testid="work-component">
      <section data-testid="viewer">
        <OpenSeadragonViewer manifestUrl={work.manifestUrl} />
      </section>
      <section className="section">
        <div className="container">
          <WorkTabs work={work} />
        </div>
      </section>
    </div>
  );
};

export default Work;
