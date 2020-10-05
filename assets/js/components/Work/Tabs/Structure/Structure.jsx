import React, { useState } from "react";
import PropTypes from "prop-types";

import useIsEditing from "@js/hooks/useIsEditing";
import { useForm, FormProvider } from "react-hook-form";
import { useMutation } from "@apollo/client";
import {
  SET_WORK_IMAGE,
  UPDATE_FILE_SETS,
} from "@js/components/Work/work.gql.js";
import { toastWrapper } from "@js/services/helpers";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import { mockFileSets } from "@js/mock-data/filesets";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";

const parseWorkRepresentativeImage = (work) => {
  if (!work.representativeImage) return;
  const arr = work.representativeImage.split("/");
  return arr[arr.length - 1];
};

const WorkTabsStructure = ({ work }) => {
  if (!work) {
    return null;
  }

  const [updateFileSets] = useMutation(UPDATE_FILE_SETS, {
    onCompleted({ updateFileSets }) {
      console.log("updateFileSets HERE", updateFileSets);
    },
  });

  const [isEditing, setIsEditing] = useIsEditing();
  const [workImageFilesetId, setWorkImageFilesetId] = useState(
    parseWorkRepresentativeImage(work)
  );
  const methods = useForm();

  const [setWorkImage] = useMutation(SET_WORK_IMAGE, {
    onCompleted({ setWorkImage }) {
      toastWrapper("is-success", "Work image has been updated");
    },
  });

  const handleDownloadClick = (type) => {
    console.log("Download clicked and type: ", type);
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
            <button
              type="button"
              className="button is-primary"
              onClick={() => setIsEditing(true)}
            >
              Edit
            </button>
          )}
          {isEditing && (
            <>
              <button type="submit" className="button is-primary">
                Save
              </button>
              <button
                type="button"
                className="button is-text"
                onClick={() => setIsEditing(false)}
              >
                Cancel
              </button>
            </>
          )}
        </UITabsStickyHeader>

        <WorkTabsStructureFilesetsDragAndDrop
          filesets={mockFileSets}
          handleDownloadClick={handleDownloadClick}
          handleWorkImageChange={handleWorkImageChange}
          isEditing={isEditing}
          workImageFilesetId={workImageFilesetId}
        />

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
              <button className="button is-primary">Download JPGs</button>
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
