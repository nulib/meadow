import React from "react";
import { Button } from "@nulib/design-system";
import { useMutation } from "@apollo/client/react";
import { useParams } from "react-router-dom";
import { useWorkState } from "@js/context/work-context";
import { GET_WORK, UPDATE_FILE_SET } from "@js/components/Work/work.gql";
import { toastWrapper } from "@js/services/helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

function IIIFViewerPosterSelector() {
  const params = useParams();
  const workId = params.id;
  const workState = useWorkState();
  const { isAuthorized } = useIsAuthorized();

  const [updateFileSet] = useMutation(UPDATE_FILE_SET, {
    onCompleted({ updateFileSet }) {
      toastWrapper(
        "is-success",
        "Poster image successfully updated.  The update should be reflected in a few seconds.  Please refresh your browser to see changes."
      );
    },
    onError({ graphQLErrors, networkError }) {
      console.error("graphQLErrors", graphQLErrors);
      console.error("networkError", networkError);
      let errorStrings = [];
      if (graphQLErrors?.length > 0) {
        errorStrings = graphQLErrors.map(
          ({ message, details }) =>
            `${message}: ${details && details.title ? details.title : ""}`
        );
      }
      toastWrapper("is-danger", errorStrings?.join(" \n ") || "General error");
    },
    refetchQueries: [
      {
        query: GET_WORK,
        variables: {
          id: workId,
        },
      },
    ],
  });

  const handleSave = () => {
    const el = document.getElementById("clover-iiif-video");
    const currentTime = el?.currentTime ? el.currentTime : 0;
    const posterOffset = parseInt(currentTime * 1000);

    updateFileSet({
      variables: {
        id: workState.activeMediaFileSet.id,
        posterOffset,
      },
    });
  };

  if (!isAuthorized()) {
    return null;
  }

  const label = workState.activeMediaFileSet.coreMetadata.label;

  return (
    <div
      className="block mt-5 is-flex is-justify-content-center"
      data-testid="set-poster-image-button"
    >
      <Button isPrimary onClick={handleSave}>
        Set poster image for &nbsp;<strong>{label}</strong>
      </Button>
    </div>
  );
}

export default IIIFViewerPosterSelector;
