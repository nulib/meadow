import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/client";
import useIsEditing from "../../../hooks/useIsEditing";
import { GET_WORK, UPDATE_WORK } from "../work.gql.js";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import UIAccordion from "../../UI/Accordion";
import UIFormField from "../../UI/Form/Field";
import UISkeleton from "../../UI/Skeleton";
import WorkTabsAboutCoreMetadata from "./About/CoreMetadata";
import WorkTabsAboutControlledMetadata from "./About/ControlledMetadata";
import WorkTabsAboutIdentifiersMetadata from "./About/IdentifiersMetadata";
import WorkTabsAboutPhysicalMetadata from "./About/PhysicalMetadata";
import WorkTabsAboutRightsMetadata from "./About/RightsMetadata";
import WorkTabsAboutUncontrolledMetadata from "./About/UncontrolledMetadata";
import WorkTabsAboutDescriptiveMetadataNoCaching from "./About/DescriptiveMetadataNoCaching";
import {
  prepControlledTermInput,
  CONTROLLED_METADATA,
} from "../../../services/metadata";
import UIError from "../../UI/Error";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;

  // Is form being edited?
  const [isEditing, setIsEditing] = useIsEditing();

  // Initialize React hook form
  const {
    register,
    handleSubmit,
    errors,
    control,
    getValues,
    formState,
    reset,
  } = useForm({
    defaultValues: {},
  });

  useEffect(() => {
    // TODO: Automate the populating of values below from DESCRIPTIVE_METADATA constant

    // Tell React Hook Form to update field array form values
    // with existing values, or when a Work updates
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
    // "data" here returns everything (which was set above in the useEffect()),
    // including fields that are either outdated or which no values were ever registered
    // with React Hook Form's register().   So, we'll use getValues() to get the real data
    // updated.
    let currentFormValues = getValues();

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
      relatedMaterial = [],
      rightsHolder = [],
      scopeAndContents = [],
      series = [],
      source = [],
      tableOfContents = [],
      title = "",
    } = currentFormValues;

    let workUpdateInput = {
      descriptiveMetadata: {
        abstract,
        alternateTitle,
        boxName,
        boxNumber,
        callNumber,
        caption,
        catalogKey,
        description,
        folderName,
        folderNumber,
        identifier,
        keywords,
        legacyIdentifier,
        license: data.license
          ? {
              id: data.license,
              scheme: "LICENSE",
            }
          : {},
        notes,
        physicalDescriptionMaterial,
        physicalDescriptionSize,
        provenance,
        publisher,
        relatedMaterial,
        rightsHolder,
        rightsStatement: data.rightsStatement
          ? {
              id: data.rightsStatement,
              scheme: "RIGHTS_STATEMENT",
            }
          : {},
        scopeAndContents,
        series,
        source,
        tableOfContents,
        title,
      },
    };

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of CONTROLLED_METADATA) {
      workUpdateInput.descriptiveMetadata[term.name] = prepControlledTermInput(
        term,
        currentFormValues[term.name]
      );
    }

    updateWork({
      variables: { id: work.id, work: workUpdateInput },
    });
  };

  if (updateWorkError) return <UIError error={updateWorkError} />;

  return (
    <form
      name="work-about-form"
      data-testid="work-about-form"
      onSubmit={handleSubmit(onSubmit)}
    >
      <UITabsStickyHeader title="Core and Descriptive Metadata">
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
      </UITabsStickyHeader>

      {isEditing ? (
        <div className="box is-relative mt-4" data-testid="uneditable-metadata">
          <h2 className="title is-size-5 mb-4">Uneditable Metadata </h2>
          <div>
            <UIFormField label="ARK">
              <p>{work.ark}</p>
            </UIFormField>
            <UIFormField label="ID">
              <p>{work.id}</p>
            </UIFormField>
            <UIFormField label="Accession Number">
              <p>{work.accessionNumber}</p>
            </UIFormField>
          </div>
        </div>
      ) : null}

      <UIAccordion testid="core-metadata-wrapper" title="Core Metadata">
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutCoreMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>

      <UIAccordion
        testid="controlled-metadata-wrapper"
        title="Creator and Subject Information"
      >
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutControlledMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>
      <UIAccordion
        testid="uncontrolled-metadata-wrapper"
        title="Description Information"
      >
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutUncontrolledMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>

      <UIAccordion
        testid="physical-metadata-wrapper"
        title="Physical Objects Information"
      >
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutPhysicalMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>
      <UIAccordion testid="rights-metadata-wrapper" title="Rights Information">
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutRightsMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>
      <UIAccordion
        testid="identifiers-metadata-wrapper"
        title="Identifiers and Relationship Information"
      >
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutIdentifiersMetadata
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            control={control}
          />
        )}
      </UIAccordion>
      {/* <div className="box is-relative">
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
        {updateWorkLoading ? (
          <UISkeleton rows={10} />
        ) : (
          <WorkTabsAboutDescriptiveMetadataNoCaching
            control={control}
            descriptiveMetadata={descriptiveMetadata}
            errors={errors}
            isEditing={isEditing}
            register={register}
            showDescriptiveMetadata={showDescriptiveMetadata}
          />
        )}
      </div> */}
    </form>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAbout;
