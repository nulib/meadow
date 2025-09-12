import React, { useContext } from "react";
import PropTypes from "prop-types";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { ImageDownloader } from "@samvera/image-downloader";
import useFileSet from "@js/hooks/useFileSet";
import { Button } from "@nulib/design-system";
import { IconDownload } from "@js/components/Icon";
import { toastWrapper } from "@js/services/helpers";
import { useWorkState } from "@js/context/work-context";
import { GET_DCAPI_ENDPOINT } from "@js/components/UI/ui.gql";
import { getApiResponse } from "@js/services/get-api-response";
import { useQuery } from "@apollo/client/react";

const WorkFilesetActionButtonsAuxiliary = ({ fileSet }) => {
  const iiifServerUrl = useContext(IIIFContext);
  const url = `${iiifServerUrl}${fileSet.id}${IIIF_SIZES.IIIF_FULL}`;
  const { altFileFormat, isImage, isAltFormat } = useFileSet();
  const { dcApiToken } = useWorkState();
  const { data: dataDcApiEndpoint } = useQuery(GET_DCAPI_ENDPOINT);

  const handleDownloadFile = async () => {
    const dcApiFileSet = `${dataDcApiEndpoint?.dcapiEndpoint?.url}/file-sets/${fileSet.id}`;
    const uri = `${dcApiFileSet}/download`;

    try {
      const response = await getApiResponse(uri, dcApiToken);
      if (response?.status !== 200) throw Error(response);
      window.location.href = response.url;
    } catch (error) {
      console.error(error);
      toastWrapper("is-danger", `The download request failed.`);
    }
  };

  return (

    <div className="buttons is-flex is-justify-content-flex-end">
      {isImage(fileSet) && (
        <div>
          <a className="button" href={url} target="_blank">
            View Aux File
          </a>
          <ImageDownloader
            imageUrl={url}
            imageTitle={fileSet.accessionNumber}
            className="button"
          >
            Download JPG
          </ImageDownloader>
        </div>
      )}

      {isAltFormat(fileSet) && (
        <div>
          <Button
            data-testid="download-file-button"
            onClick={handleDownloadFile}>
            <IconDownload />
            <span>Download {altFileFormat(fileSet)}</span>
          </Button>
        </div>
      )}

    </div>
  );
};

WorkFilesetActionButtonsAuxiliary.propTypes = {
  fileSet: PropTypes.object,
};

export default WorkFilesetActionButtonsAuxiliary;
