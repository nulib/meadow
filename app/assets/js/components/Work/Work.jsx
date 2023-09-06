import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import IIIFViewer from "@js/components/UI/IIIF/Viewer";
import PropTypes from "prop-types";
import React, { useEffect } from "react";
import WorkTabs from "./Tabs/Tabs";
import useFileSet from "@js/hooks/useFileSet";

const Work = ({ work }) => {
  const workContextState = useWorkState();
  const workDispatch = useWorkDispatch();

  const activeMediaFileSet = workContextState?.activeMediaFileSet
    ? workContextState?.activeMediaFileSet
    : work?.fileSets[0];

  const isImageWorkType =
    work.workType?.id === "IMAGE" &&
    ["AUDIO", "VIDEO"].indexOf(work.workType?.id) === -1;
  const { filterFileSets } = useFileSet();

  useEffect(() => {
    if (isImageWorkType) return;

    /**
     * If no active media file set yet exists in Context, use the first Access file set.
     * If an active file set does exist, then put the latest data from API into the Context state
     */
    let fileSet = !workContextState?.activeMediaFileSet
      ? filterFileSets(work.fileSets).access[0]
      : work.fileSets.find(
          (fs) => fs.id === workContextState.activeMediaFileSet.id
        );

    workDispatch({
      type: "updateActiveMediaFileSet",
      fileSet,
    });
  }, [work.fileSets]);

  const isViewerReady = work.manifestUrl && work.fileSets.length > 0;

  return (
    <div data-testid="work-component">
      <section>
        <div data-testid="viewer">
          {isViewerReady ? (
            <>
              <IIIFViewer
                fileSet={activeMediaFileSet}
                fileSets={[...filterFileSets(work.fileSets).access]}
                iiifContent={work.manifestUrl}
                workTypeId={work.workType?.id}
              />
            </>
          ) : (
            <p className="has-text-centered has-text-grey is-size-5">
              No filesets have been associated with this work.
            </p>
          )}
        </div>
      </section>
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
