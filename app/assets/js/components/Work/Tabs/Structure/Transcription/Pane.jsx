import React, { useEffect, useRef } from "react";

function WorkTabsStructureTranscriptionPane({
  annotation,
  hasTranscriptionCallback,
  onContentChange = () => {},
}) {
  const textAreaRef = useRef(null);
  const { content, id, status, type } = annotation || {};

  useEffect(() => {
    if (!textAreaRef.current) return;
    // While a transcription is generating, leave the textarea inert (and the
    // modal's Save disabled). Otherwise surface it to the modal as soon as it
    // mounts — even with no existing annotation — so a person can author one
    // from scratch. Hydrate any existing content first, then report it as the
    // unedited baseline so the modal's dirty tracking treats it as pristine.
    if (status === "in_progress") return;
    if (typeof content === "string") {
      textAreaRef.current.value = content;
    }
    hasTranscriptionCallback(true);
    onContentChange(textAreaRef.current.value);
  }, [content, status]);

  return (
    <div
      data-testid="transcription-pane"
      className="textarea-wrapper"
      style={{
        height: "100%",
        width: "100%",
        position: "relative",
        zIndex: 0,
      }}
    >
      {status === "in_progress" && (
        <div
          className="transcription-generating-overlay"
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            width: "100%",
            height: "100%",
            backgroundColor: "#fff6",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            zIndex: 1,
          }}
        >
          <span>Generating transcription...</span>
        </div>
      )}
      <textarea
        className="textarea"
        data-annotation-id={id}
        data-annotation-status={status}
        data-annotation-type={type}
        id="file-set-transcription-textarea"
        ref={textAreaRef}
        onChange={(e) => onContentChange(e.target.value)}
        style={{
          height: "100%",
          whiteSpace: "pre-wrap",
          minWidth: "unset",
          resize: "none",
        }}
      />
    </div>
  );
}

export default WorkTabsStructureTranscriptionPane;
