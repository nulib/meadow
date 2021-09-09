import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/admin-react-components";
import { useMutation } from "@apollo/client";
import { useParams } from "react-router-dom";
import { useWorkState } from "@js/context/work-context";
import { GET_WORK, UPDATE_FILE_SET } from "@js/components/Work/work.gql";
import { toastWrapper } from "@js/services/helpers";

function MediaPlayerPosterSelector() {
  const params = useParams();
  const workId = params.id;
  const workState = useWorkState();

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
    const el = document.getElementById("media-player");
    const posterOffset = parseInt(el.currentTime * 1000);

    updateFileSet({
      variables: {
        id: workState.activeMediaFileSet.id,
        posterOffset,
      },
    });
  };

  return (
    <div className="block is-flex">
      <Button isPrimary onClick={handleSave}>
        Set poster image
      </Button>
    </div>
  );
}

export default MediaPlayerPosterSelector;
