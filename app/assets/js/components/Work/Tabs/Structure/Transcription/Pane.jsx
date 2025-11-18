import React, { useEffect, useRef } from "react";

function WorkTabsStructureTranscriptionPane({
  annotation,
  hasTranscriptionCallback,
  isGenerating,
}) {
  const textAreaRef = useRef(null);

  useEffect(() => {
    if (annotation?.content) {
      if (textAreaRef.current) {
        textAreaRef.current.value = annotation.content;
        hasTranscriptionCallback(true);
      }
      return;
    }
  }, [annotation, isGenerating]);

  if (isGenerating && !annotation?.content) {
    return <div>Generating transcription, please wait...</div>;
  }

  return (
    <textarea
      className="textarea"
      data-annotation-id={annotation?.id}
      data-annotation-type={annotation?.type}
      id="file-set-transcription-textarea"
      ref={textAreaRef}
      style={{
        height: "100%",
        whiteSpace: "pre-wrap",
        minWidth: "unset",
        resize: "none",
      }}
    />
  );
}

export default WorkTabsStructureTranscriptionPane;
