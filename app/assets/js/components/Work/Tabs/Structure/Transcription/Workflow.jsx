import React, { useEffect } from "react";
import { Button } from "@nulib/design-system";
import WorkTabsStructureTranscriptionPane from "@js/components/Work/Tabs/Structure/Transcription/Pane";
import { TRANSCRIBE_FILE_SET } from "@js/components/Work/Tabs/Structure/Transcription/transcription.gql";
import { useMutation, useQuery } from "@apollo/client";
import { useFileSetAnnotation } from "@js/hooks/useFileSetAnnotation";
import { toastWrapper } from "@js/services/helpers";

import { GET_WORK } from "@js/components/Work/work.gql";

function WorkTabsStructureTranscriptionWorkflow({
  fileSetId,
  isActive,
  workId,
  hasTranscriptionCallback,
}) {
  const { data: { fileSetAnnotation } = {} } = useFileSetAnnotation(fileSetId);
  const {
    data: { work } = {},
    loading: workLoading,
    refetch: workRefetch,
  } = useQuery(GET_WORK, {
    variables: { id: workId },
  });

  const [transcribeFileSet] = useMutation(TRANSCRIBE_FILE_SET);

  const workFileSet = work?.fileSets?.find((fs) => fs.id === fileSetId);
  const annotation =
    fileSetAnnotation?.status === "completed"
      ? fileSetAnnotation
      : workFileSet?.annotations?.find(
          (annotation) => annotation.type === "transcription",
        );

  useEffect(() => {
    if (isActive) {
      workRefetch();
    }
  }, [isActive]);

  const handleStartTranscription = () => {
    if (!fileSetId) return;

    transcribeFileSet({
      variables: {
        fileSetId,
      },
      onCompleted: () => {
        toastWrapper("is-success", "Generating transcription");
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
      {!annotation ? (
        <Button
          isPrimary
          isLowercase
          onClick={handleStartTranscription}
          style={{ gap: "0.5rem" }}
        >
          Generate Transcription
        </Button>
      ) : (
        <WorkTabsStructureTranscriptionPane
          annotation={annotation}
          hasTranscriptionCallback={hasTranscriptionCallback}
        />
      )}
    </div>
  );
}

export default WorkTabsStructureTranscriptionWorkflow;
