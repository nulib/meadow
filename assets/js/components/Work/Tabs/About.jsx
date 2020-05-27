import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { GET_WORK, UPDATE_WORK } from "../work.gql.js";
import WorkTabsHeader from "./Header";
import UIPlaceholder from "../../UI/Placeholder";
import WorkTabsAboutCoreMetadata from "./About/CoreMetadata";
import WorkTabsAboutDescriptiveMetadata from "./About/DescriptiveMetadata";
import {
  DESCRIPTIVE_METADATA,
  prepControlledTermInput,
} from "../../../services/metadata";
import UIError from "../../UI/Error";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;

  // Whether box dropdowns are open or closed
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);

  // Is form being edited?
  const [isEditing, setIsEditing] = useIsEditing();

  // Initialize React hook form
  const { register, handleSubmit, errors, control, reset } = useForm({
    defaultValues: {},
  });

  useEffect(() => {
    // TODO: Automate the populating of values below from DESCRIPTIVE_METADATA constant

    // Tell React Hook Form to update field array form values when a Work updates
    reset({
      abstract: descriptiveMetadata.abstract,
      alternateTitle: descriptiveMetadata.alternateTitle,
      boxName: descriptiveMetadata.boxName,
      boxNumber: descriptiveMetadata.boxNumber,
      callNumber: descriptiveMetadata.callNumber,
      caption: descriptiveMetadata.caption,
      catalogKey: descriptiveMetadata.catalogKey,
      contributor: descriptiveMetadata.contributor,
      creator: descriptiveMetadata.creator,
      folderName: descriptiveMetadata.folderName,
      folderNumber: descriptiveMetadata.folderNumber,
      genre: descriptiveMetadata.genre,
      identifier: descriptiveMetadata.identifier,
      keywords: descriptiveMetadata.keywords,
      language: descriptiveMetadata.language,
      legacyIdentifier: descriptiveMetadata.legacyIdentifier,
      location: descriptiveMetadata.location,
      notes: descriptiveMetadata.notes,
      physicalDescriptionMaterial:
        descriptiveMetadata.physicalDescriptionMaterial,
      physicalDescriptionSize: descriptiveMetadata.physicalDescriptionSize,
      provenance: descriptiveMetadata.provenance,
      publisher: descriptiveMetadata.publisher,
      relatedUrl: descriptiveMetadata.relatedUrl,
      relatedMaterial: descriptiveMetadata.relatedMaterial,
      rightsHolder: descriptiveMetadata.rightsHolder,
      scopeAndContents: descriptiveMetadata.scopeAndContents,
      series: descriptiveMetadata.series,
      source: descriptiveMetadata.source,
      stylePeriod: descriptiveMetadata.stylePeriod,
      subject: descriptiveMetadata.subject,
      tableOfContents: descriptiveMetadata.tableOfContents,
      technique: descriptiveMetadata.technique,
    });
  }, [work]);

  const [
    updateWork,
    { loading: updateWorkLoading, error: updateWorkError },
  ] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work form updated successfully");
    },
    onError(error) {
      console.log("error :>> ", error);
    },
    refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
    awaitRefetchQueries: true,
  });

  // Handle About tab form submit (Core and Descriptive metadata)
  const onSubmit = (data) => {
    const {
      abstract = [],
      alternateTitle = [],
      boxName = [],
      boxNumber = [],
      callNumber = [],
      caption = [],
      catalogKey = [],
      description = "",
      folderName = [],
      folderNumber = [],
      identifier = [],
      keywords = [],
      legacyIdentifier = [],
      notes = [],
      physicalDescriptionMaterial = [],
      physicalDescriptionSize = [],
      provenance = [],
      publisher = [],
      relatedUrl = [],
      relatedMaterial = [],
      rightsHolder = [],
      scopeAndContents = [],
      series = [],
      source = [],
      tableOfContents = [],
      title = "",
    } = data;

    let workUpdateInput = {
      descriptiveMetadata: {
        abstract,
        alternateTitle,
        boxName,
        boxNumber,
        callNumber,
        caption,
        catalogKey,
        folderName,
        folderNumber,
        identifier,
        keywords,
        legacyIdentifier,
        notes,
        physicalDescriptionMaterial,
        physicalDescriptionSize,
        provenance,
        publisher,
        relatedUrl,
        relatedMaterial,
        rightsHolder,
        scopeAndContents,
        series,
        source,
        tableOfContents,
        description,
        rightsStatement: {
          id: data.rightsStatement,
        },
        title,
      },
    };

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of DESCRIPTIVE_METADATA.controlledTerms) {
      workUpdateInput.descriptiveMetadata[term.name] = prepControlledTermInput(
        data[term.name]
      );
    }

    updateWork({
      variables: { id: work.id, work: workUpdateInput },
    });
  };

  if (updateWorkError) return <UIError error={updateWorkError} />;

  return (
    <form name="work-about-form" onSubmit={handleSubmit(onSubmit)}>
      <WorkTabsHeader title="Core and Descriptive Metadata">
        {!isEditing && (
          <button
            type="button"
            className="button is-primary"
            data-testid="edit-button"
            onClick={() => setIsEditing(true)}
          >
            Edit
          </button>
        )}
        {isEditing && (
          <>
            <button
              type="submit"
              className="button is-primary"
              data-testid="save-button"
            >
              Save
            </button>
            <button
              type="button"
              className="button is-text"
              data-testid="cancel-button"
              onClick={() => setIsEditing(false)}
            >
              Cancel
            </button>
          </>
        )}
      </WorkTabsHeader>

      <div className="box is-relative" style={{ marginTop: "1rem" }}>
        <UIPlaceholder isActive={updateWorkLoading} rows={10} />

        <h2 className="title is-size-5">
          Core Metadata{" "}
          <a onClick={() => setShowCoreMetadata(!showCoreMetadata)}>
            <FontAwesomeIcon
              icon={showCoreMetadata ? "chevron-down" : "chevron-right"}
            />
          </a>
        </h2>
        <WorkTabsAboutCoreMetadata
          descriptiveMetadata={descriptiveMetadata}
          errors={errors}
          isEditing={isEditing}
          register={register}
          showCoreMetadata={showCoreMetadata}
          updateWorkLoading={updateWorkLoading}
        />
      </div>

      <div className="box is-relative">
        <UIPlaceholder isActive={updateWorkLoading} rows={10} />

        <h2 className="title is-size-5">
          Descriptive Metadata{" "}
          <a
            onClick={() => setShowDescriptiveMetadata(!showDescriptiveMetadata)}
          >
            <FontAwesomeIcon
              icon={showDescriptiveMetadata ? "chevron-down" : "chevron-right"}
            />
          </a>
        </h2>
        <WorkTabsAboutDescriptiveMetadata
          control={control}
          descriptiveMetadata={descriptiveMetadata}
          errors={errors}
          isEditing={isEditing}
          register={register}
          showDescriptiveMetadata={showDescriptiveMetadata}
        />
      </div>
    </form>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAbout;
