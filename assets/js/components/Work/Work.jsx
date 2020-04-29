import React from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";

const Work = ({ work }) => {
  return (
    <>
      <section>
        <div data-testid="viewer">
          <OpenSeadragonViewer manifestUrl={work.manifestUrl} />
        </div>
      </section>
      <section className="section">
        <div className="container">
          <WorkTabs work={work} />
        </div>
      </section>
    </>
  );
};

export default Work;
