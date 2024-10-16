import type { FileSet, Work as WorkType } from "@js/__generated__/graphql";
import React, { useEffect } from "react";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import IIIFViewer from "@js/components/UI/IIIF/Viewer";
import WorkTabs from "./Tabs/Tabs";
import useFileSet from "@js/hooks/useFileSet";
import { GET_DC_API_TOKEN } from "@js/components/Work/work.gql";
import { useQuery } from "@apollo/client";

const Work = ({ work }: { work: WorkType }) => {
  const workContextState = useWorkState();
  const workDispatch = useWorkDispatch();

  /**
   * Get the DC API super user token from the API every 5 minutes.
   */
  const {
    data: dataDcApiToken,
    error: errorDcApiToken,
    refetch: refetchDcApiToken,
  } = useQuery(GET_DC_API_TOKEN);

  const { token, expires } = dataDcApiToken?.dcApiToken || {};

  useEffect(() => {
    if (token) {
      workDispatch({
        type: "updateDcApiToken",
        dcApiToken: token,
      });
    }

    const handleTokenUpdate = setInterval(() => {
      const timePadding = 60000; // 1 minute
      const currentDate = new Date();
      const expiresDate = new Date(expires);
      const expireDifference = expiresDate.getTime() - currentDate.getTime();
      
      if (expireDifference < timePadding) {
        refetchDcApiToken();
      }
    }, 500);

    return () => clearInterval(handleTokenUpdate);
  }, [token]);

  if (errorDcApiToken) console.error(errorDcApiToken);

  const fileSets = (work.fileSets as FileSet[]) || [];

  const activeMediaFileSet = workContextState?.activeMediaFileSet
    ? workContextState?.activeMediaFileSet
    : fileSets && fileSets[0];

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
      ? filterFileSets(fileSets).access[0]
      : fileSets.find((fs) => fs.id === workContextState.activeMediaFileSet.id);

    workDispatch({
      type: "updateActiveMediaFileSet",
      fileSet,
    });
  }, [work.fileSets]);

  const isViewerReady = work.manifestUrl && fileSets.length > 0;

  if (!workContextState.dcApiToken) return null;

  return (
    <div data-testid="work-component">
      <section>
        <div data-testid="viewer">
          {isViewerReady ? (
            <IIIFViewer
              fileSet={activeMediaFileSet}
              fileSets={[...filterFileSets(fileSets).access]}
              iiifContent={work.manifestUrl}
              workTypeId={work.workType?.id}
            />
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

export default Work;
