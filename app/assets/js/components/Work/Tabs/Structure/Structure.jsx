import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import useIsEditing from "@js/hooks/useIsEditing";
import { useForm, FormProvider } from "react-hook-form";
import { useMutation } from "@apollo/client";
import {
  GET_WORK,
  GROUP_WITH_FILE_SET,
  SET_WORK_IMAGE,
  UPDATE_FILE_SETS,
  UPDATE_ACCESS_FILE_ORDER,
} from "@js/components/Work/work.gql.js";
import { UPDATE_WORK } from "@js/components/Work/work.gql.js";
import { toastWrapper } from "@js/services/helpers";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import WorkTabsStructureFilesetsDragAndDrop from "@js/components/Work/Tabs/Structure/FilesetsDragAndDrop";
import { Button, Notification } from "@nulib/design-system";
import WorkFilesetList from "@js/components/Work/Fileset/List";
import classNames from "classnames";
import { IconEdit, IconSort, IconBehaviorIndividuals, IconBehaviorContinuous, IconBehaviorPaged } from "@js/components/Icon";
import useFileSet from "@js/hooks/useFileSet";
import DownloadAll from "@js/components/UI/Modal/DownloadAll";
import BehaviorModal from "@js/components/UI/Modal/Behavior";
import { useCodeLists } from "@js/context/code-list-context";

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
    parseWorkRepresentativeImage(work),
  );
  const [isReordering, setIsReordering] = useState();
  const [isBehaviorModalVisible, setIsBehaviorModalVisible] = useState(false);
  const [error, setError] = React.useState();
  const { filterFileSets } = useFileSet();
  const codeLists = useCodeLists();
  const [behaviors, setBehaviors] = useState([]);

  const methods = useForm();

  // React Hook Form object which tracks dirty fields as user interacts with forms
  const dirtyFields = methods.formState.dirtyFields;

  // GraphQL mutations
  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    },
  });

  const [groupWithFileSet] = useMutation(GROUP_WITH_FILE_SET, {
    onCompleted({ updateFileSet }) {
      const groupWithAction = updateFileSet?.groupWith
        ? "added to"
        : "removed from";
      toastWrapper("is-success", `File set has been ${groupWithAction} group`);
    },
  });

  const [updateFileSets, { loading: loadingUpdateFilesets }] = useMutation(
    UPDATE_FILE_SETS,
    {
      onCompleted({ updateFileSets }) {
        toastWrapper("is-success", "File sets have been updated");
        setIsEditing(false);
      },
      onError(error) {
        console.error(
          "error in the updateFileSets GraphQL mutation :>> ",
          error,
        );
        setError({
          message: "There was an error updating file sets.",
          responseError: error,
        });
      },
    },
  );

  const [updateAccessFileOrder] = useMutation(UPDATE_ACCESS_FILE_ORDER, {
    onCompleted() {
      setIsReordering(false);
      toastWrapper(
        "is-success",
        "Access copies have been successfully reordered.",
      );
    },
    onError(error) {
      console.error("error in the updateWork GraphQL mutation :>> ", error);
    },
    refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
    awaitRefetchQueries: true,
  });

  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      toastWrapper("is-success", "Work behavior updated successfully");
      setIsBehaviorModalVisible(false);
    },
    onError(error) {
      toastWrapper("is-danger", "Error updating work behavior");
      console.error("Error updating work behavior", error);
    },
    refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
    awaitRefetchQueries: true,
  });

  useEffect(() => {
    if (codeLists.behaviorData) {
      setBehaviors(codeLists.behaviorData.codeList);
    }
  }, [codeLists.behaviorData]);

  const handleCancelReorder = () => {
    setIsReordering(false);
  };

  const handleSaveReorder = (orderedFileSets = []) => {
    updateAccessFileOrder({
      variables: { workId: work.id, fileSetIds: orderedFileSets },
    });
  };

  const handleGroupWithUpdate = (groupWithFileSets) => {
    groupWithFileSets.forEach((fs) => {
      groupWithFileSet({
        variables: { id: fs.id, groupWith: fs.group_with },
      });
    });
  };

  const handleWorkImageChange = (id) => {
    if (id === workImageFilesetId) return;

    setWorkImageFilesetId(id === workImageFilesetId ? null : id);
    setWorkImage({ variables: { fileSetId: id, workId: work.id } });
  };

  const handleBehaviorSave = (behaviorId) => {
    if (!behaviorId) {
      toastWrapper("is-warning", "Please select a valid display type");
      return;
    }
    updateWork({
      variables: {
        id: work.id,
        work: {
          behavior: {
            id: behaviorId,
            scheme: "BEHAVIOR",
          }
        }
      }
    });
  };

  const filterDraggableFilesets = (fileSets) => {
    const accessFiles = fileSets.filter((fs) => fs.role.id === "A");
    return affirmOrder(accessFiles);
  };

  const onSubmit = (data) => {
    const ids = Object.keys(data);
    const dirtyFieldIds = Object.keys(dirtyFields);
    const filteredIds = ids.filter((id) => dirtyFieldIds.includes(id));
    let formPostData = [];

    for (let id of filteredIds) {
      formPostData.push({
        id,
        coreMetadata: {
          label: data[id].label,
          description: data[id].description,
        },
      });
    }

    updateFileSets({ variables: { fileSets: formPostData } });
  };

  const getBehaviorIcon = () => {
    const behaviorId = work?.behavior?.id || "individuals";
    switch (behaviorId) {
      case "continuous":
        return <IconBehaviorContinuous />;
      case "paged":
        return <IconBehaviorPaged />;
      case "individuals":
      default:
        return <IconBehaviorIndividuals />;
    }
  };

  function affirmOrder(fileSets) {
    const { idMap, groupedMap } = fileSets.reduce(
      (acc, fileSet) => {
        acc.idMap.set(fileSet.id, fileSet);
        if (fileSet.group_with) {
          if (!acc.groupedMap.has(fileSet.group_with)) {
            acc.groupedMap.set(fileSet.group_with, []);
          }
          acc.groupedMap.get(fileSet.group_with).push(fileSet);
        }
        return acc;
      },
      { idMap: new Map(), groupedMap: new Map() },
    );

    return fileSets.reduce((orderedList, fileSet) => {
      if (!fileSet.group_with || !idMap.has(fileSet.group_with)) {
        orderedList.push(fileSet);
        if (groupedMap.has(fileSet.id)) {
          orderedList.push(...groupedMap.get(fileSet.id));
        }
      }
      return orderedList;
    }, []);
  }

  return (
    <FormProvider {...methods}>
      <form
        name="work-structure-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader title="Access & Auxiliary Filesets">
          {!isEditing && (
            <Button
              isPrimary
              onClick={() => setIsEditing(true)}
              disabled={isReordering}
            >
              <IconEdit />
              <span>Edit</span>
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
            onClick={() => setIsBehaviorModalVisible(true)}
            disabled={isEditing || isReordering}
          >
            {getBehaviorIcon()}
            <span>Display</span>
          </Button>

          <Button
            onClick={() => setIsReordering(true)}
            disabled={isEditing || isReordering}
          >
            <IconSort />
            <span>Re-order & Group</span>
          </Button>

          {work?.workType?.id === "IMAGE" && <DownloadAll workId={work?.id} />}
        </UITabsStickyHeader>

        <BehaviorModal
          isVisible={isBehaviorModalVisible}
          behaviors={behaviors}
          currentBehavior={work?.behavior?.id}
          onClose={() => setIsBehaviorModalVisible(false)}
          onSave={handleBehaviorSave}
        />

        <div className="mt-4">
          {error && (
            <Notification isDanger>
              {`${error.message}`}
              <br />
              <br /> {`${error.responseError.toString()}`}
            </Notification>
          )}
          {isReordering ? (
            <WorkTabsStructureFilesetsDragAndDrop
              fileSets={filterDraggableFilesets(work.fileSets)}
              handleCancelReorder={handleCancelReorder}
              handleSaveReorder={handleSaveReorder}
              handleGroupWithUpdate={handleGroupWithUpdate}
            />
          ) : (
            <WorkFilesetList
              fileSets={filterFileSets(work.fileSets)}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
              work={work}
            />
          )}
        </div>
      </form>
    </FormProvider>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsStructure;
