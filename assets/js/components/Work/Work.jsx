import React from "react";
import OpenSeadragonViewer from "openseadragon-react-viewer";
import WorkTabAbout from "./TabAbout";

const Work = ({ work }) => {
  return (
    <div data-testid="work">
      <section>
        <OpenSeadragonViewer manifestUrl="https://iiif.stack.rdc.library.northwestern.edu/public/06/20/ea/ca/-5/4e/6-/41/81/-a/85/8-/39/dd/ea/0b/b1/c5-manifest.json" />
      </section>

      <section className="section">
        <div className="container">
          <div className="tabs is-centered is-boxed" data-testid="tabs">
            <ul>
              <li className="is-active">
                <a>About this item</a>
              </li>
              <li>
                <a>Administrative</a>
              </li>
              <li>
                <a>Structure</a>
              </li>
              <li>
                <a>Preservation</a>
              </li>
            </ul>
          </div>
          <div className="tabs-container">
            <WorkTabAbout work={work} />
          </div>
        </div>
      </section>
    </div>
  );
};

export default Work;
