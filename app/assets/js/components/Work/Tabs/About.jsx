import {
  CONTROLLED_METADATA,
  IDENTIFIER_METADATA,
  PHYSICAL_METADATA,
  RIGHTS_METADATA,
  UNCONTROLLED_METADATA,
  convertFieldArrayValToHookFormVal,
  deleteKeyFromObject,
  prepControlledTermInput,
  prepEDTFforPost,
  prepFieldArrayItemsForPost,
  prepNotes,
  prepRelatedUrl,
} from "@js/services/metadata";
import { FormProvider, useForm } from "react-hook-form";
import { GET_WORK, UPDATE_WORK } from "../work.gql.js";
import React, { useEffect, useState } from "react";
import { Skeleton, TabsStickyHeader } from "@js/components/UI/UI";

import { Button } from "@nulib/design-system";
import { IconEdit } from "@js/components/Icon";
import PropTypes from "prop-types";
import UIAccordion from "../../UI/Accordion";
import UIError from "../../UI/Error";
import WorkTabsAboutControlledMetadata from "./About/ControlledMetadata";
import WorkTabsAboutCoreMetadata from "./About/CoreMetadata";
import WorkTabsAboutIdentifiersMetadata from "./About/IdentifiersMetadata";
import WorkTabsAboutPhysicalMetadata from "./About/PhysicalMetadata";
import WorkTabsAboutRightsMetadata from "./About/RightsMetadata";
import WorkTabsAboutUncontrolledMetadata from "./About/UncontrolledMetadata";
import { toastWrapper } from "../../../services/helpers";
import useIsEditing from "../../../hooks/useIsEditing";
import { useMutation } from "@apollo/client/react";

function prepFormData(work) {
  const { descriptiveMetadata } = work;
  let resetValues = {};
  let controlledTermResetValues = {};

  // Convert data data from the API for a shape the form (and React Hook Form) want.
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
        convertFieldArrayValToHookFormVal(value),
      );
    }
  }

  // Prepare Controlled Term back-end data for a shape the form wants
  // We can just pass back-end values straight through for controlled terms
  for (let obj of CONTROLLED_METADATA) {
    controlledTermResetValues[obj.name] = [...descriptiveMetadata[obj.name]];
  }

  return {
    alternateTitle: descriptiveMetadata.alternateTitle.map((value) => ({
      metadataItem: value,
    })),
    description: descriptiveMetadata.description.map((value) => ({
      metadataItem: value,
    })),
    dateCreated: descriptiveMetadata.dateCreated.map((value) => ({
      metadataItem: value.edtf,
    })),
    notes: descriptiveMetadata.notes,
    relatedUrl: descriptiveMetadata.relatedUrl,
    ...resetValues,
    ...controlledTermResetValues,
  };
}

const WorkTabsAbout = ({ work }) => {
  const workData = prepFormData(work);

  // Initialize React Hook Form
  const methods = useForm({ defaultValues: { ...workData } });

  const { descriptiveMetadata } = work;

  // Is form being edited?
  const [isEditing, setIsEditing] = useIsEditing();

  useEffect(() => {
    // Tell React Hook Form to update field array form values
    // with existing values, or when a Work updates
    const updatedData = prepFormData(work);
    methods.reset(updatedData);
  }, [work]);

  const [updateWork, { loading: updateWorkLoading, error: updateWorkError }] =
    useMutation(UPDATE_WORK, {
      onCompleted({ updateWork }) {
        setIsEditing(false);
        toastWrapper("is-success", "Work metadata successfully updated");
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
    // with React Hook Form's register().   So, we'll use getValues() to get the most accurate data.

    let currentFormValues = methods.getValues();

    const { title = "" } = currentFormValues;

    let workUpdateInput = {
      descriptiveMetadata: {
        alternateTitle: prepFieldArrayItemsForPost(
          currentFormValues.alternateTitle,
        ),
        dateCreated: prepEDTFforPost(currentFormValues.dateCreated),
        description: prepFieldArrayItemsForPost(currentFormValues.description),
        license: data.license
          ? {
              id: data.license,
              scheme: "LICENSE",
            }
          : {},
        notes: prepNotes(currentFormValues.notes),
        relatedUrl: prepRelatedUrl(currentFormValues.relatedUrl),
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

    // Convert form field array items from an array of objects to array of strings
    for (let group of [
      IDENTIFIER_METADATA,
      PHYSICAL_METADATA,
      RIGHTS_METADATA,
      UNCONTROLLED_METADATA,
    ]) {
      for (let term of group) {
        workUpdateInput.descriptiveMetadata[term.name] =
          prepFieldArrayItemsForPost(currentFormValues[term.name]);
      }
    }

    // Update controlled term values to match shape the GraphQL mutation expects
    for (let term of CONTROLLED_METADATA) {
      workUpdateInput.descriptiveMetadata[term.name] = prepControlledTermInput(
        term,
        currentFormValues[term.name],
      );
    }

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
        <TabsStickyHeader title="Core and Descriptive Metadata">
          {!isEditing && (
            <Button
              isPrimary
              data-testid="edit-button"
              onClick={() => setIsEditing(true)}
            >
              <IconEdit />
              <span>Edit</span>
            </Button>
          )}
          {isEditing && (
            <>
              <Button isPrimary type="submit" data-testid="save-button">
                Save
              </Button>
              <Button
                isText
                data-testid="cancel-button"
                onClick={() => setIsEditing(false)}
              >
                Cancel
              </Button>
            </>
          )}
        </TabsStickyHeader>

        <UIAccordion testid="core-metadata-wrapper" title="Core Metadata">
          {updateWorkLoading ? (
            <Skeleton rows={10} />
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
            <Skeleton rows={10} />
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
            <Skeleton rows={10} />
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
            <Skeleton rows={10} />
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
            <Skeleton rows={10} />
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
            <Skeleton rows={10} />
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

export default React.memo(WorkTabsAbout);
