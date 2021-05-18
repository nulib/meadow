import React from "react";
import { OpenSeadragonViewer } from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";
import PropTypes from "prop-types";
import UIMediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import {
  mockVideoSources,
  mockVideoTracks,
} from "@js/components/UI/MediaPlayer/MediaPlayer";

const osdOptions = {
  showDropdown: true,
  showThumbnails: true,
  showToolbar: true,
  deepLinking: false,
  height: 800,
};

const Work = ({ work }) => {
  const [manifestObj, setManifestObj] = React.useState();
  const [randomUrlKey, setRandomUrlKey] = React.useState(Date.now());
  const [manifestChangeItems, setManifestChangeItems] = React.useState({
    label: "",
    canvasCount: "",
  });

  React.useEffect(() => {
    async function getData() {
      const response = await fetch(`${work.manifestUrl}?${Date.now()}`);
      const data = await response.json();

      // Check if watch items in manifest are different.
      // If so, trigger a re-render of OSD viewer
      if (
        data.label !== manifestChangeItems.label ||
        data.sequences[0].canvases.length !== manifestChangeItems.canvasCount
      ) {
        setManifestChangeItems({
          label: data.label,
          canvasCount: data.sequences[0].canvases.length,
        });
        setRandomUrlKey(Date.now());
      }
      setManifestObj(data);
    }

    getData();
  }, [work.fileSets, work.descriptiveMetadata.title]);

  return (
    <>
      <section>
        <div data-testid="viewer">
          {manifestObj && (
            <OpenSeadragonViewer
              //manifestUrl={`${work.manifestUrl}?timestamp=${Date.now()}`}
              manifest={manifestObj}
              options={osdOptions}
              key={`${work.id}_${randomUrlKey}`}
            />
          )}
        </div>
      </section>
      <section className="section">
        <UIMediaPlayer
          controls
          autoPlay
          sources={mockVideoSources}
          tracks={mockVideoTracks}
        />
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
