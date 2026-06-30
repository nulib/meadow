import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { IconDownload } from "@js/components/Icon";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { WORK_ARCHIVER_ENDPOINT, GET_WORK } from "@js/components/Work/work.gql";
import { useQuery } from "@apollo/client/react";
import { toastWrapper, downloadBlob } from "@js/services/helpers";
import { zipSync, strToU8 } from "fflate";

/** @jsx jsx */
import { jsx } from "@emotion/react";
import styled from "@emotion/styled";

const Radio = styled.input`
  margin-right: 3px;
`;

const UIDownloadAll = ({ workId }) => {
  const [isModalVisible, setIsModalVisible] = React.useState(false);
  const [downloadType, setDownloadType] = React.useState("images");
  const [width, setWidth] = React.useState("1500");
  const [transcriptionFormat, setTranscriptionFormat] =
    React.useState("combined");
  const { user } = useIsAuthorized();

  const { loading, error, data } = useQuery(WORK_ARCHIVER_ENDPOINT);
  const { data: workData } = useQuery(GET_WORK, {
    variables: { id: workId },
    skip: !workId,
  });

  if (loading) return <p>Loading...</p>;
  if (error) return <p>{error}</p>;

  const work = workData?.work;

  const transcriptionFileSets = (work?.fileSets || [])
    .map((fs) => ({
      accessionNumber: fs.accessionNumber,
      id: fs.id,
      content: fs.annotations?.find(
        (a) => a.type === "transcription" && a.status === "completed",
      )?.content,
    }))
    .filter((fs) => fs.content);

  const hasTranscriptions = transcriptionFileSets.length > 0;

  function handleOpenModal() {
    // Default to images; only switch if the work has transcriptions and user had selected
    // transcriptions before — keep last selection unless it's no longer valid.
    if (!hasTranscriptions) setDownloadType("images");
    setIsModalVisible(true);
  }

  function handleCancelClick() {
    setIsModalVisible(false);
  }

  function handleRadioChange(e) {
    setWidth(e.target.value);
  }

  function handleTranscriptionFormatChange(e) {
    setTranscriptionFormat(e.target.value);
  }

  function handleSubmit() {
    const url = data.workArchiverEndpoint.url;

    fetch(
      `${url}?${new URLSearchParams({
        workId,
        email: user.email,
        width,
      })}`,
      {
        method: "POST",
      },
    )
      .then((response) => {
        if (!response.ok) {
          throw new Error(
            "Bad network request posting to work archiver endpoint",
          );
        }
        toastWrapper(
          "is-success",
          `Your images are being packaged and you'll receive an email shortly with a link to download.`,
        );
        setIsModalVisible(false);
      })
      .catch((error) => console.error(`Error: ${error}`));
  }

  function handleDownloadTranscriptions() {
    if (transcriptionFileSets.length === 0) {
      toastWrapper("is-danger", "No transcriptions to download");
      return;
    }

    const workLabel = work?.accessionNumber || work?.id || workId;

    if (transcriptionFormat === "combined") {
      const text = transcriptionFileSets
        .map(
          (fs) => `===== ${fs.accessionNumber || fs.id} =====\n\n${fs.content}`,
        )
        .join("\n\n");
      const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
      downloadBlob(blob, `transcriptions-${workLabel}.txt`);
    } else {
      const seenNames = {};
      const files = {};
      transcriptionFileSets.forEach((fs) => {
        const baseName = fs.accessionNumber || fs.id;
        const count = seenNames[baseName] || 0;
        seenNames[baseName] = count + 1;
        const filename =
          count === 0
            ? `transcription-${baseName}.txt`
            : `transcription-${baseName}-${count}.txt`;
        files[filename] = strToU8(fs.content);
      });
      const zipped = zipSync(files);
      const blob = new Blob([zipped], { type: "application/zip" });
      downloadBlob(blob, `transcriptions-${workLabel}.zip`);
    }
  }

  return (
    <>
      <Button data-testid="download-all-button" onClick={handleOpenModal}>
        <IconDownload />
        <span>Download all</span>
      </Button>

      <div
        className={classNames("modal", { "is-active": isModalVisible })}
        data-testid="download-all-modal"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <div className="modal-card-head">
            <p className="modal-card-title">Download all filesets</p>
            <button
              className="delete"
              aria-label="close"
              onClick={handleCancelClick}
            ></button>
          </div>

          <section className="modal-card-body">
            {/* Step 1: choose what to download (only shown when transcriptions exist) */}
            {hasTranscriptions && (
              <UIFormField label="What would you like to download?">
                <div
                  className="control"
                  data-testid="radio-download-type"
                  style={{ display: "flex", gap: "1.5rem" }}
                >
                  <label className="radio">
                    <Radio
                      type="radio"
                      name="downloadType"
                      value="images"
                      checked={downloadType === "images"}
                      onChange={(e) => setDownloadType(e.target.value)}
                    />
                    Images
                  </label>
                  <label className="radio">
                    <Radio
                      type="radio"
                      name="downloadType"
                      value="transcriptions"
                      checked={downloadType === "transcriptions"}
                      onChange={(e) => setDownloadType(e.target.value)}
                    />
                    Transcriptions
                  </label>
                </div>
              </UIFormField>
            )}

            {/* Step 2: options for the chosen type */}
            {downloadType === "images" && (
              <>
                <UIFormField label="Email">
                  <p data-testid="email">{user.email}</p>
                </UIFormField>

                <UIFormField label="Select image width">
                  <div className="control" data-testid="radio-image-size">
                    <label className="radio">
                      <Radio
                        type="radio"
                        name="width"
                        value="1500"
                        checked={width === "1500"}
                        onChange={handleRadioChange}
                      />
                      1500
                    </label>
                    <label className="radio">
                      <Radio
                        type="radio"
                        name="width"
                        value="3000"
                        checked={width === "3000"}
                        onChange={handleRadioChange}
                      />
                      3000
                    </label>
                    <label className="radio">
                      <Radio
                        type="radio"
                        name="width"
                        value="full"
                        checked={width === "full"}
                        onChange={handleRadioChange}
                      />
                      full
                    </label>
                  </div>
                </UIFormField>
              </>
            )}

            {downloadType === "transcriptions" && (
              <UIFormField label="Select format">
                <div
                  className="control"
                  data-testid="radio-transcription-format"
                >
                  <label className="radio">
                    <Radio
                      type="radio"
                      name="transcriptionFormat"
                      value="combined"
                      checked={transcriptionFormat === "combined"}
                      onChange={handleTranscriptionFormatChange}
                    />
                    Combined text file (.txt)
                  </label>
                  <label className="radio">
                    <Radio
                      type="radio"
                      name="transcriptionFormat"
                      value="zip"
                      checked={transcriptionFormat === "zip"}
                      onChange={handleTranscriptionFormatChange}
                    />
                    Separate files (.zip)
                  </label>
                </div>
              </UIFormField>
            )}
          </section>

          <footer className="modal-card-foot buttons is-right">
            <Button
              isText
              onClick={handleCancelClick}
              aria-label="close"
              data-testid="cancel-button"
            >
              Cancel
            </Button>

            {downloadType === "images" ? (
              <Button
                isPrimary
                onClick={handleSubmit}
                data-testid="submit-button"
              >
                Start download job
              </Button>
            ) : (
              <Button
                isPrimary
                onClick={handleDownloadTranscriptions}
                data-testid="download-transcriptions-button"
              >
                <IconDownload />
                <span>Download transcriptions</span>
              </Button>
            )}
          </footer>
        </div>
      </div>
    </>
  );
};

UIDownloadAll.propTypes = {
  workId: PropTypes.string,
};

export default UIDownloadAll;
