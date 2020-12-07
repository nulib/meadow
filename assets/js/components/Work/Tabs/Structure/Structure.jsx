import React, { useState } from "react";
import PropTypes from "prop-types";
import useIsEditing from "@js/hooks/useIsEditing";
import { useForm, FormProvider } from "react-hook-form";
import { useMutation } from "@apollo/client";
import {
  GET_WORK,
  SET_WORK_IMAGE,
  UPDATE_FILE_SETS,
  UPDATE_FILE_SET_ORDER,
} from "@js/components/Work/work.gql.js";
import { toastWrapper } from "@js/services/helpers";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";
import { Button } from "@nulib/admin-react-components";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import WorkTabsStructureFilesetList from "./FilesetList";

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

  const methods = useForm();

  // GraphQL mutations
  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    },
  });
  const [updateFileSets] = useMutation(UPDATE_FILE_SETS, {
    onCompleted({ updateFileSets }) {
      console.log("onCompleted() updateFileSets", updateFileSets);
    },
  });
  const [updateFileSetOrder] = useMutation(UPDATE_FILE_SET_ORDER, {
    onCompleted() {
      setIsReordering(false);
      toastWrapper("is-success", "Filesets have been successfully reordered.");
    },
    onError(error) {
      console.log("error in the updateWork GraphQL mutation :>> ", error);
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
    updateFileSetOrder({
      variables: { workId: work.id, fileSetIds: orderedFileSets },
    });
  };

  const handleWorkImageChange = (id) => {
    if (id === workImageFilesetId) return;

    setWorkImageFilesetId(id === workImageFilesetId ? null : id);
    setWorkImage({ variables: { fileSetId: id, workId: work.id } });
  };

  const onSubmit = (data) => {
    // TODO : add logic to update filesets for given work.
    console.log(data);

    // Send POST data to mutation
    // Looks like?
    /**
     * [{
     *  id,
     *  metadata: {
     *    label: "",
     *    description: ""
     * }
     * }]
     *
     */
    updateFileSets({ variables: { items: ["ABC123"] } });
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
              <Button isPrimary type="submit">
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
          {isReordering ? (
            <WorkTabsStructureFilesetsDragAndDrop
              fileSets={work.fileSets}
              handleCancelReorder={handleCancelReorder}
              handleSaveReorder={handleSaveReorder}
            />
          ) : (
            <WorkTabsStructureFilesetList
              fileSets={work.fileSets}
              handleDownloadClick={handleDownloadClick}
              handleWorkImageChange={handleWorkImageChange}
              isEditing={isEditing}
              workImageFilesetId={workImageFilesetId}
            />
          )}
        </div>

        <div className="box">
          <h3 className="subtitle">Download all files as zip</h3>
          <div className="columns">
            <div className="column">
              <div className="field">
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize1"
                />
                <label htmlFor="downloadsize1"> Full size</label>
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize2"
                />
                <label htmlFor="downloadsize2"> 3000x3000</label>
                <input
                  type="radio"
                  className="is-checkradio"
                  name="downloadsize"
                  id="downloadsize3"
                />
                <label htmlFor="downloadsize3"> 1000x1000</label>
              </div>
            </div>

            <div className="column buttons has-text-right">
              <button className="button">Download Tiffs</button>
              <button className="button">Download JPGs</button>
            </div>
          </div>
        </div>
      </form>
    </FormProvider>
  );
};

WorkTabsStructure.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsStructure;
