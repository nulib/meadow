import React, { useEffect, useRef } from "react";

function WorkTabsStructureTranscriptionPane({
  annotation,
  hasTranscriptionCallback,
}) {
  const textAreaRef = useRef(null);
  const { content, id, status, type } = annotation;

  useEffect(() => {
    if (!textAreaRef.current) return;
    if (typeof content === "string") {
      hasTranscriptionCallback(true);
      textAreaRef.current.value = content;
      return;
    }
  }, [content]);

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
