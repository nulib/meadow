import React from "react";
import { OpenSeadragonViewer } from "openseadragon-react-viewer";
import WorkTabs from "./Tabs/Tabs";
import PropTypes from "prop-types";
import { getManifest } from "@js/services/get-manifest";
import MediaPlayerWrapper from "@js/components/UI/MediaPlayer/Wrapper";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
import useFileSet from "@js/hooks/useFileSet";
import { useQuery } from "@apollo/client";
import { GET_IIIF_MANIFEST_HEADERS } from "./work.gql";

const osdOptions = {
  showDropdown: true,
  showThumbnails: true,
  showToolbar: true,
  deepLinking: false,
  height: 800,
};

const Work = ({ work }) => {
  const [manifestObj, setManifestObj] = React.useState();
  const [manifestKey, setManifestKey] = React.useState("abc");
  const workContextState = useWorkState();
  const workDispatch = useWorkDispatch();

  const isImageWorkType =
    work.workType?.id === "IMAGE" &&
    ["AUDIO", "VIDEO"].indexOf(work.workType?.id) === -1;
  const { filterFileSets } = useFileSet();

  useQuery(GET_IIIF_MANIFEST_HEADERS, {
    variables: { workId: work.id },
    pollInterval: 1000,
    onCompleted: (data) => {
      if (data.iiifManifestHeaders.etag)
        setManifestKey(data.iiifManifestHeaders.etag);
    },
  });

  React.useEffect(() => {
    workDispatch({ type: "updateWorkType", workTypeId: work.workType.id });

    async function getData() {
      const data = await getManifest(`${work.manifestUrl}?${Date.now()}`);
      if (!data) return;
      setManifestObj(data);
    }

    isImageWorkType && getData();
  }, []);

  React.useEffect(() => {
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

  return (
    <div data-testid="work-component">
      {isImageWorkType && (
        <section>
          <div data-testid="viewer">
            {manifestObj && (
              <OpenSeadragonViewer
                manifest={manifestObj}
                options={osdOptions}
                key={manifestKey}
              />
            )}
          </div>
        </section>
      )}

      {!isImageWorkType && (
        <MediaPlayerWrapper
          fileSet={workContextState?.activeMediaFileSet}
          fileSets={[...filterFileSets(work.fileSets).access]}
          manifestId={work.manifestUrl}
          manifestKey={manifestKey}
          workTypeId={work.workType?.id}
        />
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
