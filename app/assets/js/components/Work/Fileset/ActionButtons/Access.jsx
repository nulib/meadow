import React, { useContext } from "react";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";

import { AuthContext } from "@js/components/Auth/Auth";
import { Button } from "@nulib/design-system";
import { GET_DCAPI_ENDPOINT } from "@js/components/UI/ui.gql";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { IconDownload } from "@js/components/Icon";
import { ImageDownloader } from "@samvera/image-downloader";
import PropTypes from "prop-types";
import { getApiResponse } from "@js/services/get-api-response";
import { toastWrapper } from "@js/services/helpers";
import useFileSet from "@js/hooks/useFileSet";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { useQuery } from "@apollo/client";

export function MediaButtons({ fileSet }) {
  const [downloadStarted, setDownloadStarted] = React.useState(false);

  const dispatch = useWorkDispatch();
  const { dcApiToken } = useWorkState();
  const currentUser = useContext(AuthContext);

  const { getWebVttString } = useFileSet();
  const { isAuthorized } = useIsAuthorized();
  const { data: dataDcApiEndpoint } = useQuery(GET_DCAPI_ENDPOINT);

  const handleDownloadMedia = async () => {
    setDownloadStarted(true);

    const dcApiFileSet = `${dataDcApiEndpoint?.dcapiEndpoint?.url}/file-sets/${fileSet.id}`;
    const uri = `${dcApiFileSet}/download?email=${currentUser?.email}`;

    try {
      const response = await getApiResponse(uri, dcApiToken);
      if (response?.status !== 200) throw Error(response);

      toastWrapper(
        "is-success",
        `Your media for <em>${fileSet.coreMetadata.label}</em> is being prepared for download. You will receive an email at <strong>${currentUser?.email}</strong> when it is ready.`,
      );
    } catch (error) {
      console.error(error);
      toastWrapper("is-danger", `The download request failed.`);
    }
  };

  if (!fileSet) return null;

  return (
    <div className="buttons is-grouped is-right">
      {isAuthorized() && (
        <Button
          data-testid="edit-structure-button"
          onClick={() =>
            dispatch({
              type: "toggleWebVttModal",
              fileSetId: fileSet?.id,
              webVttString: getWebVttString(fileSet),
            })
          }
        >
          Edit structure (vtt)
        </Button>
      )}
      <Button
        data-testid="download-fileset-button"
        onClick={handleDownloadMedia}
        disabled={downloadStarted}
      >
        <IconDownload />
        Download
      </Button>
    </div>
  );
}

export function ImageButtons({ iiifServerUrl, fileSet }) {
  return (
    <div
      data-testid="download-image-fileset"
      className="field has-addons is-flex is-justify-content-flex-end"
    >
      <p className="control">
        <a
          href={`${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL_TIFF}`}
          target="_blank"
          className="button"
        >
          <span className="icon">
            <IconDownload />
          </span>{" "}
          <span>TIF</span>
        </a>
      </p>
      <p className="control">
        <ImageDownloader
          imageUrl={`${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL}`}
          imageTitle={fileSet.accessionNumber}
          className="button"
        >
          JPG
        </ImageDownloader>
      </p>
    </div>
  );
}

const WorkFilesetActionButtonsAccess = ({ fileSet }) => {
  const iiifServerUrl = useContext(IIIFContext);
  const { isImage, isMedia } = useFileSet();

  if (isImage(fileSet)) {
    return <ImageButtons iiifServerUrl={iiifServerUrl} fileSet={fileSet} />;
  }
  if (isMedia(fileSet)) {
    return <MediaButtons fileSet={fileSet} />;
  }
};

WorkFilesetActionButtonsAccess.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkFilesetActionButtonsAccess;
