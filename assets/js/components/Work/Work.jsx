import React from "react";
import { OpenSeadragonViewer } from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";
import PropTypes from "prop-types";
import UIMediaPlayer from "@js/components/UI/MediaPlayer/MediaPlayer";
import {
  mockVideoSources,
  mockVideoTracks,
} from "@js/components/UI/MediaPlayer/MediaPlayer";
import { getManifest } from "@js/services/get-manifest";

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
  const isImageWorkType =
    work.workType?.id === "IMAGE" &&
    ["AUDIO", "VIDEO"].indexOf(work.workType?.id) === -1;

  React.useEffect(() => {
    async function getData() {
      const data = await getManifest(`${work.manifestUrl}?${Date.now()}`);

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

    isImageWorkType && getData();
  }, [work.fileSets, work.descriptiveMetadata.title]);

  return (
    <div data-testid="work-component">
      {isImageWorkType && (
        <section>
          <div data-testid="viewer">
            {manifestObj && (
              <OpenSeadragonViewer
                manifest={manifestObj}
                options={osdOptions}
                key={`${work.id}_${randomUrlKey}`}
              />
            )}
          </div>
        </section>
      )}

      {!isImageWorkType && (
        <section className="section">
          <div className="container">
            <p className="notification is-warning is-light has-text-centered">
              Audio/video Work Type player not yet supported
            </p>
            {/* <UIMediaPlayer
            controls
            sources={mockVideoSources}
            tracks={mockVideoTracks}
          /> */}
          </div>
        </section>
      )}

      <section className="section">
        <div className="container" data-testid="tabs-wrapper">
          <WorkTabs work={work} />
        </div>
      </section>
    </div>
  );
};

Work.propTypes = {
  work: PropTypes.object,
};

export default Work;
