import React, { useContext, useEffect, useState } from "react";
import PropTypes from "prop-types";
import CloverImage from "@samvera/clover-iiif/image";
import { Button } from "@nulib/design-system";
import classNames from "classnames";
import { useWorkDispatch, useWorkState } from "@js/context/work-context";
import { IIIFContext } from "@js/components/IIIF/IIIFProvider";
import { IIIF_SIZES } from "@js/services/global-vars";
import { toastWrapper } from "@js/services/helpers";
import { useMutation } from "@apollo/client";
import { UPDATE_FILE_SET_ANNOTATION } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import WorkTabsStructureTranscriptionWorkflow from "@js/components/Work/Tabs/Structure/Transcription/Workflow";

function WorkTabsStructureTranscriptionModal({ isActive }) {
  const [textArea, setTextArea] = useState();

  const dispatch = useWorkDispatch();
  const iiifServerUrl = useContext(IIIFContext);
  const {
    transcriptionModal: { fileSetId },
    work: { id: workId },
  } = useWorkState();

  const iiifImageUrl = `${iiifServerUrl}${fileSetId}${IIIF_SIZES.IIIF_FULL}`;

  const [updateFileSetAnnotation] = useMutation(UPDATE_FILE_SET_ANNOTATION);

  useEffect(() => {
    const textAreaElement = document.getElementById(
      "file-set-transcription-textarea",
    );
    setTextArea(textAreaElement);
  }, [isActive]);

  const handleClose = () => {
    dispatch({
      type: "toggleTranscriptionModal",
      fileSetId: null,
    });
  };

  const handleSaveTranscription = () => {
    const annotationContent = textArea?.value || "";
    const annotationId = textArea?.getAttribute("data-annotation-id");

    updateFileSetAnnotation({
      variables: {
        annotationId: annotationId,
        content: annotationContent,
      },
      onCompleted: () => {
        handleClose();
        toastWrapper("is-success", "Transcription successfully saved");
      },
      onError: (error) => {
        toastWrapper(
          "is-danger",
          "Error saving transcription: " + error.message,
        );
      },
    });
  };

  const handleHasTranscriptionCallback = () => {
    const textAreaElement = document.getElementById(
      "file-set-transcription-textarea",
    );
    setTextArea(textAreaElement);
  };

  const hasTextArea = Boolean(textArea);

  return (
    <div className={classNames(["modal"], { "is-active": isActive })}>
      <div className="modal-background" />
      <div className="modal-card" style={{ width: "90%", maxWidth: "1344px" }}>
        <header className="modal-card-head">
          <p className="modal-card-title">Transcription</p>
          <button
            type="button"
            className="delete"
            aria-label="close"
            onClick={handleClose}
          />
        </header>

        <section className="modal-card-body">
          <div
            className="is-flex is-justify-content-space-between"
            style={{ gap: "1rem" }}
          >
            <div style={{ width: "50%", flexShrink: 0 }}>
              <div
                className="box"
                style={{
                  height: "400px",
                  padding: 0,
                  position: "relative",
                  zIndex: 0,
                }}
              >
                <CloverImage
                  src={iiifImageUrl || ""}
                  openSeadragonConfig={{
                    showNavigator: false,
                  }}
                />
              </div>
            </div>
            <WorkTabsStructureTranscriptionWorkflow
              fileSetId={fileSetId}
              key={fileSetId}
              workId={workId}
              hasTranscriptionCallback={handleHasTranscriptionCallback}
              isActive={isActive}
            />
          </div>
        </section>

        <footer className="modal-card-foot buttons is-justify-content-space-between">
          <div className="is-flex is-justify-content-flex-end is-flex-grow-1">
            <Button onClick={handleClose}>Cancel</Button>
            <Button
              isPrimary
              disabled={!hasTextArea}
              onClick={handleSaveTranscription}
            >
              Save
            </Button>
          </div>
        </footer>
      </div>
    </div>
  );
}

WorkTabsStructureTranscriptionModal.propTypes = {
  isActive: PropTypes.bool,
};

export default WorkTabsStructureTranscriptionModal;
