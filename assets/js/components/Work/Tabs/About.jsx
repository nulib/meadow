import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { toastWrapper } from "../../../services/helpers";
import { useForm, FormProvider } from "react-hook-form";
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
import {
  convertFieldArrayValToHookFormVal,
  prepControlledTermInput,
  prepFieldArrayItemsForPost,
  prepRelatedUrl,
  CONTROLLED_METADATA,
  IDENTIFIER_METADATA,
  PHYSICAL_METADATA,
  RIGHTS_METADATA,
  UNCONTROLLED_METADATA,
} from "../../../services/metadata";
import UIError from "../../UI/Error";

const WorkTabsAbout = ({ work }) => {
  // Initialize React Hook Form
  const methods = useForm({ defaultValues: {} });

  const { descriptiveMetadata } = work;

  // Is form being edited?
  const [isEditing, setIsEditing] = useIsEditing();

  useEffect(() => {
    // Tell React Hook Form to update field array form values
    // with existing values, or when a Work updates
    let resetValues = {};
    let controlledTermResetValues = {};

    // Prepare back-end data for a shape the form (and React Hook Form) want
    // These are all field array form items: type [String], and we need
    // to turn them into: type [Object] ie. [{ metadataItem: "value here" }]
    for (let group of [
      IDENTIFIER_METADATA,
      PHYSICAL_METADATA,
      RIGHTS_METADATA,
      UNCONTROLLED_METADATA,
    ]) {
      for (let obj of group) {
        resetValues[obj.name] = descriptiveMetadata[obj.name].map((value) =>
          convertFieldArrayValToHookFormVal(value)
        );
      }
    }

    // Prepare Controlled Term back-end data for a shape the form wants
    // We can just pass back-end values straight through for controlled terms
    for (let obj of CONTROLLED_METADATA) {
      controlledTermResetValues[obj.name] = [...descriptiveMetadata[obj.name]];
    }

    methods.reset({
      alternateTitle: descriptiveMetadata.alternateTitle.map((value) => ({
        metadataItem: value,
      })),
      description: descriptiveMetadata.description.map((value) => ({
        metadataItem: value,
      })),
      dateCreated: descriptiveMetadata.dateCreated,
      relatedUrl: descriptiveMetadata.relatedUrl,
      ...resetValues,
      ...controlledTermResetValues,
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
      console.log("error in the updateWork GraphQL mutation :>> ", error);
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
    let currentFormValues = methods.getValues();
    const { description = "", title = "" } = currentFormValues;

    let workUpdateInput = {
      descriptiveMetadata: {
        alternateTitle: prepFieldArrayItemsForPost(
          currentFormValues.alternateTitle
        ),
        dateCreated: currentFormValues.dateCreated || [],
        description: prepFieldArrayItemsForPost(currentFormValues.description),
        license: data.license
          ? {
              id: data.license,
              scheme: "LICENSE",
            }
          : {},
        rightsStatement: data.rightsStatement
          ? {
              id: data.rightsStatement,
              scheme: "RIGHTS_STATEMENT",
            }
          : {},
        title,
        termsOfUse: data.termsOfUse,
      },
    };

    console.log(workUpdateInput);

    // Convert form field array items from an array of objects to array of strings
    for (let group of [
      IDENTIFIER_METADATA,
      PHYSICAL_METADATA,
      RIGHTS_METADATA,
      UNCONTROLLED_METADATA,
    ]) {
      for (let term of group) {
        workUpdateInput.descriptiveMetadata[
          term.name
        ] = prepFieldArrayItemsForPost(currentFormValues[term.name]);
      }
    }

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of CONTROLLED_METADATA) {
      workUpdateInput.descriptiveMetadata[term.name] = prepControlledTermInput(
        term,
        currentFormValues[term.name]
      );
    }

    // Update Related Url, which is a unique controlled term
    workUpdateInput.descriptiveMetadata.relatedUrl = prepRelatedUrl(
      currentFormValues.relatedUrl
    );

    updateWork({
      variables: {
        id: work.id,
        work: workUpdateInput,
      },
    });
  };

  // TODO: Eventually figure out why this doesn't get set on certain GraphQL errors?
  if (updateWorkError) return <UIError error={updateWorkError} />;

  return (
    <FormProvider {...methods}>
      <form
        name="work-about-form"
        data-testid="work-about-form"
        onSubmit={methods.handleSubmit(onSubmit)}
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
          <div
            className="box is-relative content mt-4"
            data-testid="uneditable-metadata"
          >
            <div className="columns">
              <div className="column">
                <UIFormField label="ARK">
                  <p>{work.ark}</p>
                </UIFormField>
              </div>
              <div className="column">
                <UIFormField label="ID">
                  <p>{work.id}</p>
                </UIFormField>
              </div>
              <div className="column">
                <UIFormField label="Accession Number">
                  <p>{work.accessionNumber}</p>
                </UIFormField>
              </div>
            </div>
          </div>
        ) : null}

        <UIAccordion testid="core-metadata-wrapper" title="Core Metadata">
          {updateWorkLoading ? (
            <UISkeleton rows={10} />
          ) : (
            <WorkTabsAboutCoreMetadata
              descriptiveMetadata={descriptiveMetadata}
              isEditing={isEditing}
              published={work.published}
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
              isEditing={isEditing}
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
              isEditing={isEditing}
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
              isEditing={isEditing}
            />
          )}
        </UIAccordion>
        <UIAccordion
          testid="rights-metadata-wrapper"
          title="Rights Information"
        >
          {updateWorkLoading ? (
            <UISkeleton rows={10} />
          ) : (
            <WorkTabsAboutRightsMetadata
              descriptiveMetadata={descriptiveMetadata}
              isEditing={isEditing}
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
              isEditing={isEditing}
            />
          )}
        </UIAccordion>
      </form>
    </FormProvider>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAbout;
