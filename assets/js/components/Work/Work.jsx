import React from "react";
import { OpenSeadragonViewer } from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";
import PropTypes from "prop-types";

const osdOptions = {
  showDropdown: true,
  showThumbnails: true,
  showToolbar: true,
  deepLinking: true,
  height: 800,
};

const Work = ({ work }) => {
  return (
    <>
      <section>
        <div data-testid="viewer">
          <OpenSeadragonViewer
            manifestUrl={work.manifestUrl}
            options={osdOptions}
          />
        </div>
      </section>
      <section className="section">
        <div className="container" data-testid="tabs-wrapper">
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
