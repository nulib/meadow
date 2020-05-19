import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { GET_WORK, UPDATE_WORK } from "../work.query";
import WorkTabsHeader from "./Header";
import UIPlaceholder from "../../UI/Placeholder";
import WorkTabsAboutCoreMetadata from "./About/CoreMetadata";
import WorkTabsAboutDescriptiveMetadata from "./About/DescriptiveMetadata";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);
  const [isEditing, setIsEditing] = useIsEditing();

  const genericDescriptiveMetadata = [
    { name: "abstract", label: "Abstract" },
    { name: "alternateTitle", label: "Alternate Title" },
    { name: "boxName", label: "Box Name" },
    { name: "boxNumber", label: "Box Number" },
    { name: "callNumber", label: "Call Number" },
    { name: "caption", label: "Caption" },
    { name: "catalogKey", label: "Catalog Key" },
    { name: "folderName", label: "Folder Name" },
    { name: "folderNumber", label: "Folder Number" },
    { name: "identifier", label: "Identifier" },
    { name: "keywords", label: "Keywords" },
    { name: "legacyIdentifier", label: "Legacy Identifier" },
    { name: "notes", label: "Notes" },
    {
      name: "physicalDescriptionMaterial",
      label: "Physical Description Material",
    },
    { name: "physicalDescriptionSize", label: "Physical Description Size" },
    { name: "provenance", label: "Provenance" },
    { name: "publisher", label: "Publisher" },
    { name: "relatedUrl", label: "Related URL" },
    { name: "relatedMaterial", label: "Related Material" },
    { name: "rightsHolder", label: "Rights Holder" },
    { name: "scopeAndContents", label: "Scope and Content" },
    { name: "series", label: "Series" },
    { name: "source", label: "Source" },
    { name: "tableOfContents", label: "Table of Contents" },
  ];
  // React hook form setup
  const { register, handleSubmit, errors, control, reset } = useForm({
    // Declare form "field array" fields here
    defaultValues: {},
  });

  useEffect(() => {
    // Tell React Hook Form to update field array form values when a Work updates
    reset({
      abstract: descriptiveMetadata.abstract,
      alternateTitle: descriptiveMetadata.alternateTitle,
      boxName: descriptiveMetadata.boxName,
      boxNumber: descriptiveMetadata.boxNumber,
      callNumber: descriptiveMetadata.callNumber,
      caption: descriptiveMetadata.caption,
      catalogKey: descriptiveMetadata.catalogKey,
      folderName: descriptiveMetadata.folderName,
      folderNumber: descriptiveMetadata.folderNumber,
      identifier: descriptiveMetadata.identifier,
      keywords: descriptiveMetadata.keywords,
      legacyIdentifier: descriptiveMetadata.legacyIdentifier,
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
      tableOfContents: descriptiveMetadata.tableOfContents,
    });
  }, [work]);

  const [updateWork, { loading: updateWorkLoading }] = useMutation(
    UPDATE_WORK,
    {
      onCompleted({ updateWork }) {
        setIsEditing(false);
        toastWrapper("is-success", "Work form updated successfully");
      },
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    }
  );

  const onSubmit = (data) => {
    console.log("data :>> ", data);
    const {
      abstract = [],
      alternateTitle = [],
      boxName = [],
      boxNumber = [],
      callNumber = [],
      caption = [],
      catalogKey = [],
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
      description = "",
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

    updateWork({
      variables: { id: work.id, work: workUpdateInput },
    });
  };

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
          genericDescriptiveMetadata={genericDescriptiveMetadata}
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
