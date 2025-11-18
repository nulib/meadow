import React, { useEffect, useState } from "react";
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
  const [isGenerating, setIsGenerating] = useState(false);

  const { data } = useFileSetAnnotation(fileSetId);

  const { data: { work } = {}, refetch } = useQuery(GET_WORK, {
    variables: { id: workId },
  });

  const [transcribeFileSet] = useMutation(TRANSCRIBE_FILE_SET);

  const fileSet = work?.fileSets?.find((fs) => fs.id === fileSetId);
  const annotation =
    data?.fileSetAnnotation?.status === "completed"
      ? data?.fileSetAnnotation
      : fileSet?.annotations?.find(
          (annotation) => annotation.type === "transcription",
        );

  const hasTranscription = Boolean(annotation);

  useEffect(() => {
    if (hasTranscription) setIsGenerating(false);
  }, [hasTranscription]);

  useEffect(() => {
    if (isActive) {
      refetch();
    }
  }, [isActive]);

  const handleStartTranscription = () => {
    if (!fileSet?.id) return;

    transcribeFileSet({
      variables: {
        fileSetId: fileSet.id,
      },
      onCompleted: () => {
        toastWrapper("is-success", "Generating transcription");
        setIsGenerating(true);
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

  return (
    <div
      data-generating={isGenerating}
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
      {isGenerating || hasTranscription ? (
        <WorkTabsStructureTranscriptionPane
          annotation={annotation}
          hasTranscriptionCallback={hasTranscriptionCallback}
          isGenerating={isGenerating}
        />
      ) : (
        <Button
          isPrimary
          isLowercase
          onClick={handleStartTranscription}
          style={{ gap: "0.5rem" }}
        >
          Generate Transcription
        </Button>
      )}
    </div>
  );
}

export default WorkTabsStructureTranscriptionWorkflow;
