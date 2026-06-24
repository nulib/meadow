import React, { useEffect, useRef, useState } from "react";
import { Button } from "@nulib/design-system";
import WorkTabsStructureTranscriptionPane from "@js/components/Work/Tabs/Structure/Transcription/Pane";
import {
  DELETE_FILE_SET_ANNOTATION,
  TRANSCRIBE_FILE_SET,
} from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import { useMutation, useQuery } from "@apollo/client/react";
import { useFileSetAnnotation } from "@js/hooks/useFileSetAnnotation";
import { toastWrapper } from "@js/services/helpers";

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
  const [deleteFileSetAnnotation] = useMutation(DELETE_FILE_SET_ANNOTATION);

  const workFileSet = work?.fileSets?.find((fs) => fs.id === fileSetId);
  const existingTranscriptionAnnotation = workFileSet?.annotations?.find(
    (annotation) => annotation.type === "transcription",
  );
  const annotation =
    fileSetAnnotation?.status === "completed"
      ? fileSetAnnotation
      : existingTranscriptionAnnotation;

  const failedAnnotationId =
    (fileSetAnnotation?.status === "error" && fileSetAnnotation?.id) ||
    (existingTranscriptionAnnotation?.status === "error" &&
      existingTranscriptionAnnotation?.id) ||
    null;
  const annotationFailed = Boolean(failedAnnotationId);

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

  const runTranscribeMutation = () => {
    transcribeFileSet({
      variables: {
        fileSetId,
      },
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

  const handleStartTranscription = async () => {
    if (!fileSetId) return;

    toastWrapper("is-success", "Generating transcription");

    if (failedAnnotationId) {
      try {
        await deleteFileSetAnnotation({
          variables: { annotationId: failedAnnotationId },
          refetchQueries: [{ query: GET_WORK, variables: { id: workId } }],
          awaitRefetchQueries: true,
        });
      } catch (error) {
        flashTranscriptionError(error);
        return;
      }
    }

    runTranscribeMutation();
  };

  if (workLoading) return null;

  return (
    <div
      data-annotation={annotation?.id}
      style={{
        width: "50%",
        flexGrow: 1,
        flexShrink: 1,
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      {!annotation || annotationFailed ? (
        manualEntry ? (
          <WorkTabsStructureTranscriptionPane
            annotation={{
              content: "",
              id: null,
              status: "completed",
              type: "transcription",
            }}
            hasTranscriptionCallback={hasTranscriptionCallback}
            onContentChange={onContentChange}
          />
        ) : (
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
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
        )
      ) : (
        <WorkTabsStructureTranscriptionPane
          annotation={annotation}
          hasTranscriptionCallback={hasTranscriptionCallback}
          onContentChange={onContentChange}
        />
      )}
    </div>
  );
}

export default WorkTabsStructureTranscriptionWorkflow;
