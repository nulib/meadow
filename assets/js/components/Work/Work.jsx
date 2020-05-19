import React from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";
import PropTypes from "prop-types";

const Work = ({ work }) => {
  return (
    <>
      {/* <section>
        <div data-testid="viewer">
          <OpenSeadragonViewer manifestUrl={work.manifestUrl} />
        </div>
      </section> */}
      <section className="section">
        <div className="container">
          <WorkTabs work={work} />
        </div>
      </section>
    </>
  );
};

Work.propTypes = {
  work: PropTypes.object,
};

export default Work;
