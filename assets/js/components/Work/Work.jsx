import React, { useState } from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";

const Work = ({ work }) => {
  return (
    <div data-testid="work-component">
      <section data-testid="viewer">
        {/* <OpenSeadragonViewer manifestUrl="https://iiif.stack.rdc.library.northwestern.edu/public/06/20/ea/ca/-5/4e/6-/41/81/-a/85/8-/39/dd/ea/0b/b1/c5-manifest.json" /> */}
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
