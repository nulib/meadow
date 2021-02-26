import React, { useState } from "react";
import PropTypes from "prop-types";
import useIsEditing from "@js/hooks/useIsEditing";
import { useForm, FormProvider } from "react-hook-form";
import { useMutation } from "@apollo/client";
import {
  GET_WORK,
  SET_WORK_IMAGE,
  UPDATE_FILE_SETS,
  UPDATE_ACCESS_MASTER_ORDER,
} from "@js/components/Work/work.gql.js";
import { toastWrapper } from "@js/services/helpers";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import WorkTabsStructureFilesetList from "./FilesetList";
import WorkTabsStructureDownloadAll from "@js/components/Work/Tabs/Structure/DownloadAll";
import classNames from "classnames";

const parseWorkRepresentativeImage = (work) => {
  if (!work.representativeImage) return;
  const arr = work.representativeImage.split("/");
  return arr[arr.length - 1];
};

const WorkTabsStructure = ({ work }) => {
  if (!work) {
    return null;
  }
  const [isEditing, setIsEditing] = useIsEditing();
  const [workImageFilesetId, setWorkImageFilesetId] = useState(
    parseWorkRepresentativeImage(work)
  );
  const [isReordering, setIsReordering] = useState();
  const [error, setError] = React.useState();

  const methods = useForm();

  // React Hook Form object which tracks dirty fields as user interacts with forms
  const dirtyFields = methods.formState.dirtyFields;

  // GraphQL mutations
  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    },
  });
  const [updateFileSets, { loading: loadingUpdateFilesets }] = useMutation(
    UPDATE_FILE_SETS,
    {
      onCompleted({ updateFileSets }) {
        console.log("updateFileSets", updateFileSets);
        toastWrapper("is-success", "Filesets have been updated");
        setIsEditing(false);
      },
      onError(error) {
        console.error(
          "error in the updateFileSets GraphQL mutation :>> ",
          error
        );
        setError({
          message: "There was an error updating file sets.",
          responseError: error,
        });
      },
    }
  );
  const [updateAccessMasterOrder] = useMutation(UPDATE_ACCESS_MASTER_ORDER, {
    onCompleted() {
      setIsReordering(false);
      toastWrapper(
        "is-success",
        "Access masters have been successfully reordered."
      );
    },
    onError(error) {
      console.error("error in the updateWork GraphQL mutation :>> ", error);
    },
    refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
    awaitRefetchQueries: true,
  });

  const handleCancelReorder = () => {
    setIsReordering(false);
  };

  const handleDownloadClick = (type) => {
    console.log("Download clicked and type: ", type);
  };

  const handleSaveReorder = (orderedFileSets = []) => {
    updateAccessMasterOrder({
      variables: { workId: work.id, fileSetIds: orderedFileSets },
    });
  };

  const handleWorkImageChange = (id) => {
    if (id === workImageFilesetId) return;

    setWorkImageFilesetId(id === workImageFilesetId ? null : id);
    setWorkImage({ variables: { fileSetId: id, workId: work.id } });
  };

  const filterAccessMasters = (fileSets) => {
    return fileSets.filter((fs) => fs.role.id == "A");
  };

  const onSubmit = (data) => {
    const ids = Object.keys(data);
    const dirtyFieldIds = Object.keys(dirtyFields);
    const filteredIds = ids.filter((id) => dirtyFieldIds.includes(id));
    let formPostData = [];

    for (let id of filteredIds) {
      formPostData.push({
        id,
        metadata: {
          label: data[id].label,
          description: data[id].description,
        },
      });
    }

    updateFileSets({ variables: { fileSets: formPostData } });
  };

  return (
    <FormProvider {...methods}>
      <form
        name="work-structure-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader title="Filesets">
          {!isEditing && (
            <Button
              isPrimary
              onClick={() => setIsEditing(true)}
              disabled={isReordering}
            >
              Edit
            </Button>
          )}
          {isEditing && (
            <>
              <Button
                isPrimary
                type="submit"
                className={classNames({
                  "is-loading": loadingUpdateFilesets,
                })}
              >
                Save
              </Button>
              <Button isText onClick={() => setIsEditing(false)}>
                Cancel
              </Button>
            </>
          )}

          <Button
            onClick={() => setIsReordering(true)}
            disabled={isEditing || isReordering}
          >
            <span className="icon">
              <FontAwesomeIcon icon="sort" />
            </span>{" "}
            <span>Re-order</span>
          </Button>
        </UITabsStickyHeader>

        <div className="mt-4">
          {error && (
            <p className="notification is-danger">
              {`${error.message}`}
              <br />
              <br /> {`${error.responseError.toString()}`}
            </p>
          )}
          {isReordering ? (
            <WorkTabsStructureFilesetsDragAndDrop
              fileSets={filterAccessMasters(work.fileSets)}
              handleCancelReorder={handleCancelReorder}
              handleSaveReorder={handleSaveReorder}
            />
          ) : (
            <WorkTabsStructureFilesetList
              fileSets={filterAccessMasters(work.fileSets)}
              handleDownloadClick={handleDownloadClick}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
            />
          )}
        </div>

        <WorkTabsStructureDownloadAll />
      </form>
    </FormProvider>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsStructure;
