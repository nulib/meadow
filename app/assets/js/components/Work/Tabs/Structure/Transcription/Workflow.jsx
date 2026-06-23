import React, { useEffect, useRef, useState } from "react";
import { Button } from "@nulib/design-system";
import WorkTabsStructureTranscriptionPane from "@js/components/Work/Tabs/Structure/Transcription/Pane";
import { TRANSCRIBE_FILE_SET } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import { useMutation, useQuery } from "@apollo/client/react";
import { useFileSetAnnotation } from "@js/hooks/useFileSetAnnotation";
import { toastWrapper } from "@js/services/helpers";
import { AnnotationOriginBadge } from "@js/components/AIProvenance/Badges";

import { GET_WORK } from "@js/components/Work/work.gql";

const humanizeFieldName = (field) =>
  field.replace(/_/g, " ").replace(/^./, (c) => c.toUpperCase());

const humanizeMessage = (message) => message.replace(/file_set/g, "file set");

const formatDetails = (details) => {
  if (!details) return "";
  if (typeof details === "string") return details;

  return Object.entries(details)
    .map(([field, message]) => {
      const text = Array.isArray(message) ? message.join(", ") : message;
      return `${humanizeFieldName(field)}: ${text}`;
    })
    .join("; ");
};

const flashTranscriptionError = (error) => {
  const graphQLErrors = error?.graphQLErrors || error?.errors || [];

  if (graphQLErrors.length === 0) {
    toastWrapper(
      "is-danger",
      error?.message || "There was an error generating transcription.",
    );
    return;
  }

  graphQLErrors.forEach(({ message, details, extensions }) => {
    const detailText = formatDetails(details || extensions?.details);
    const flashMessage = detailText
      ? `${humanizeMessage(message)} — ${detailText}`
      : humanizeMessage(message);
    toastWrapper("is-danger", flashMessage);
  });
};

function WorkTabsStructureTranscriptionWorkflow({
  fileSetId,
  isActive,
  workId,
  hasTranscriptionCallback,
  onContentChange,
}) {
  const flashedAnnotationErrorIdRef = useRef(null);
  const [manualEntry, setManualEntry] = useState(false);
  const { data: { fileSetAnnotation } = {} } = useFileSetAnnotation(fileSetId);
  const {
    data: { work } = {},
    loading: workLoading,
    refetch: workRefetch,
  } = useQuery(GET_WORK, {
    variables: { id: workId },
  });

  const [transcribeFileSet] = useMutation(TRANSCRIBE_FILE_SET);
  const [useExistingAsContext, setUseExistingAsContext] = useState(false);
  const [hasContent, setHasContent] = useState(false);

  const workFileSet = work?.fileSets?.find((fs) => fs.id === fileSetId);
  const existingTranscriptionAnnotation = workFileSet?.annotations?.find(
    (annotation) => annotation.type === "transcription",
  );
  const annotation =
    fileSetAnnotation?.status === "completed"
      ? fileSetAnnotation
      : existingTranscriptionAnnotation;

  // Hide the Generate button while a transcription is being produced so it
  // can't be triggered twice; the backend replaces any existing one, so there
  // is no failed-annotation cleanup to do here anymore.
  const generating = [fileSetAnnotation?.status, annotation?.status].some(
    (status) => status === "pending" || status === "in_progress",
  );

  useEffect(() => {
    if (isActive) {
      workRefetch();
    }
  }, [isActive]);

  useEffect(() => {
    if (
      fileSetAnnotation?.status === "error" &&
      flashedAnnotationErrorIdRef.current !== fileSetAnnotation.id
    ) {
      const detail = fileSetAnnotation.error;
      toastWrapper(
        "is-danger",
        detail
          ? `Transcription failed: ${detail}`
          : "Transcription failed. Please try again.",
      );
      flashedAnnotationErrorIdRef.current = fileSetAnnotation.id;
    }
  }, [
    fileSetAnnotation?.id,
    fileSetAnnotation?.status,
    fileSetAnnotation?.error,
  ]);

  const handleStartTranscription = () => {
    if (!fileSetId) return;

    // Send the live editor text (incl. unsaved edits) as context when the
    // reviewer opts in — matches what they see and works even before a first
    // save. The backend replaces any existing transcription.
    const liveText =
      document.getElementById("file-set-transcription-textarea")?.value || "";
    const context =
      useExistingAsContext && liveText.trim() ? liveText : undefined;

    toastWrapper("is-success", "Generating transcription");

    transcribeFileSet({
      variables: { fileSetId, ...(context ? { context } : {}) },
      onError: (error) => {
        flashTranscriptionError(error);
      },
      refetchQueries: [
        {
          query: GET_WORK,
          variables: { id: workId },
        },
      ],
      awaitRefetchQueries: true,
    });
  };

  if (workLoading) return null;

  // The Generate button stays available so an existing — human or AI —
  // transcription can be regenerated, except while one is being produced. When
  // there is content to draw on, a checkbox offers to feed it to the model as
  // context for the regeneration.
  const canGenerate = !generating;

  // No annotation and no manual draft yet: offer the reviewer Karen's two-way
  // entry choice — let the model generate one, or open a blank editor to type
  // one in by hand. Once either path is taken (or an annotation exists), the
  // editor below takes over.
  const showEditor = Boolean(annotation) || manualEntry;

  return (
    <div
      data-annotation={annotation?.id}
      style={{
        width: "50%",
        flexGrow: 1,
        flexShrink: 1,
        display: "flex",
        flexDirection: "column",
        minHeight: 0,
      }}
    >
      {!showEditor ? (
        <div
          style={{
            display: "flex",
            flexGrow: 1,
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: "0.75rem",
          }}
        >
          <Button
            isPrimary
            isLowercase
            onClick={handleStartTranscription}
            style={{ gap: "0.5rem" }}
          >
            Generate Transcription
          </Button>
          <Button isLowercase onClick={() => setManualEntry(true)}>
            Enter Manually
          </Button>
        </div>
      ) : (
        <>
          <div
            className="is-flex is-align-items-center is-justify-content-space-between mb-2"
            style={{ gap: "0.5rem", minHeight: "2rem" }}
          >
            <AnnotationOriginBadge annotation={annotation} />
            {canGenerate && (
              <div
                className="is-flex is-align-items-center is-justify-content-flex-end"
                style={{ gap: "0.75rem" }}
              >
                {hasContent && (
                  <label className="checkbox is-size-7">
                    <input
                      type="checkbox"
                      className="mr-1"
                      checked={useExistingAsContext}
                      onChange={(e) =>
                        setUseExistingAsContext(e.target.checked)
                      }
                    />
                    Use existing transcription as context
                  </label>
                )}
                <Button
                  isPrimary
                  isLowercase
                  isSmall
                  onClick={handleStartTranscription}
                  style={{ gap: "0.5rem" }}
                >
                  Generate Transcription
                </Button>
              </div>
            )}
          </div>
          <WorkTabsStructureTranscriptionPane
            annotation={
              annotation || {
                content: "",
                id: null,
                status: "completed",
                type: "transcription",
              }
            }
            hasTranscriptionCallback={hasTranscriptionCallback}
            onContentChange={(value) => {
              setHasContent(Boolean(value && value.trim()));
              onContentChange?.(value);
            }}
          />
        </>
      )}
    </div>
  );
}

export default WorkTabsStructureTranscriptionWorkflow;
