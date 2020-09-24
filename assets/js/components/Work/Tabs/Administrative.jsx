import React, { useEffect } from "react";
import PropTypes from "prop-types";
import { useQuery, useMutation } from "@apollo/client";
import useIsEditing from "../../../hooks/useIsEditing";
import { toastWrapper } from "../../../services/helpers";
import { GET_COLLECTIONS } from "../../Collection/collection.gql.js";
import { UPDATE_WORK, GET_WORK } from "../work.gql.js";
import { useForm, FormProvider } from "react-hook-form";
import UIFormSelect from "../../UI/Form/Select";
import UIFormField from "../../UI/Form/Field";
import UITabsStickyHeader from "../../UI/Tabs/StickyHeader";
import { CODE_LIST_QUERY } from "../controlledVocabulary.gql.js";
import UICodedTermItem from "../../UI/CodedTerm/Item";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormInput from "../../UI/Form/Input.jsx";
import UIFormFieldArrayDisplay from "../../UI/Form/FieldArrayDisplay";
import UISkeleton from "../../UI/Skeleton";
import {
  PROJECT_METADATA,
  prepFieldArrayItemsForPost,
} from "../../../services/metadata";
import { Button } from "@nulib/admin-react-components";

const WorkTabsAdministrative = ({ work }) => {
  console.log("LOADS");
  const { id, administrativeMetadata, collection, published } = work;
  const [isEditing, setIsEditing] = useIsEditing();

  const {
    data: collectionsData,
    loading: collectionsLoading,
    error: collectionsError,
  } = useQuery(GET_COLLECTIONS);

  const [
    updateWork,
    { loading: updateWorkLoading, error: updateWorkError },
  ] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work form updated successfully");
    },
    refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
    awaitRefetchQueries: true,
  });
  const { preservationLevel, status, projectCycle } = administrativeMetadata;

  const methods = useForm({
    defaultValues: {},
  });

  useEffect(() => {
    console.log("useEffect");
    let resetValues = {};
    for (let group of [PROJECT_METADATA]) {
      for (let obj of group) {
        resetValues[obj.name] = administrativeMetadata[obj.name].map(
          (value) => ({
            metadataItem: value,
          })
        );
      }
    }
    methods.reset({
      ...resetValues,
      projectCycle: administrativeMetadata.projectCycle,
    });
  }, [work]);

  // Get select dropdown options.  Need a better way to organize this
  const {
    loading: preservationLevelsLoading,
    error: preservationLevelsError,
    data: preservationLevelsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "PRESERVATION_LEVEL" },
  });
  const {
    loading: statusLoading,
    error: statusError,
    data: statusData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "STATUS" },
  });
  const {
    loading: visibilityLoading,
    error: visibilityError,
    data: visibilityData,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "VISIBILITY" } });

  const onSubmit = (data) => {
    let currentFormValues = methods.getValues();

    let workUpdateInput = {
      administrativeMetadata: {
        preservationLevel: currentFormValues.preservationLevel
          ? {
              id: currentFormValues.preservationLevel,
              scheme: "PRESERVATION_LEVEL",
            }
          : {},
        status: currentFormValues.status
          ? { id: currentFormValues.status, scheme: "STATUS" }
          : {},

        projectCycle: currentFormValues.projectCycle,
      },
      collectionId: currentFormValues.collection,
      visibility: currentFormValues.visibility
        ? { id: currentFormValues.visibility, scheme: "VISIBILITY" }
        : {},
    };

    for (let term of PROJECT_METADATA) {
      workUpdateInput.administrativeMetadata[
        term.name
      ] = prepFieldArrayItemsForPost(currentFormValues[term.name]);
    }

    updateWork({
      variables: { id, work: workUpdateInput },
    });
  };

  if (
    collectionsLoading ||
    preservationLevelsLoading ||
    statusLoading ||
    visibilityLoading ||
    updateWorkLoading
  ) {
    <UISkeleton rows={10} />;
  }

  if (
    collectionsError ||
    preservationLevelsError ||
    statusError ||
    visibilityError ||
    updateWorkError
  ) {
    return (
      <p className="notification is-danger">
        There was an error loading GraphQL data on the Work Administrative tab
      </p>
    );
  }

  return (
    <FormProvider {...methods}>
      <form
        name="work-administrative-form"
        data-testid="work-administrative-form"
        onSubmit={methods.handleSubmit(onSubmit)}
      >
        <UITabsStickyHeader title="Administrative Metadata">
          {!isEditing && (
            <Button
              type="button"
              className="button is-primary"
              onClick={() => setIsEditing(true)}
              data-testid="edit-button"
            >
              Edit
            </Button>
          )}
          {isEditing && (
            <>
              <Button
                type="submit"
                className="button is-primary"
                data-testid="save-button"
              >
                Save
              </Button>
              <Button
                data-testid="cancel-button"
                type="button"
                className="button is-text"
                onClick={() => setIsEditing(false)}
              >
                Cancel
              </Button>
            </>
          )}
        </UITabsStickyHeader>

        <div className="columns">
          <div className="column is-two-thirds">
            <div className="box is-relative">
              {/* <UIPlaceholder isActive={updateWorkLoading} rows={10} /> */}
              <UIFormField label="Collection">
                {isEditing ? (
                  <UIFormSelect
                    isReactHookForm
                    name="collection"
                    label="Collection"
                    showHelper={true}
                    options={collectionsData.collections.map((collection) => ({
                      id: collection.id,
                      value: collection.id,
                      label: collection.title,
                    }))}
                    defaultValue={collection ? collection.id : ""}
                  />
                ) : (
                  <p>
                    {collection ? collection.title : "Not part of a collection"}
                  </p>
                )}
              </UIFormField>

              <UIFormField label="Preservation Level" required={published}>
                {isEditing ? (
                  <UIFormSelect
                    isReactHookForm
                    name="preservationLevel"
                    showHelper={true}
                    label="Preservation Level"
                    options={preservationLevelsData.codeList}
                    defaultValue={preservationLevel ? preservationLevel.id : ""}
                    required={work.published}
                  />
                ) : (
                  <p>
                    {preservationLevel
                      ? preservationLevel.label
                      : "None selected"}
                  </p>
                )}
              </UIFormField>

              <UIFormField label="Status" required={published}>
                {isEditing ? (
                  <UIFormSelect
                    data-testid="status"
                    isReactHookForm
                    name="status"
                    label="Status"
                    showHelper={true}
                    options={statusData.codeList}
                    defaultValue={status ? status.id : ""}
                    required={work.published}
                  />
                ) : (
                  <p>{status ? status.label : "None selected"}</p>
                )}
              </UIFormField>

              <UIFormField label="Themes" mocked notLive>
                <p>Nothing yet</p>
              </UIFormField>

              <UIFormField label="Visibility">
                {isEditing ? (
                  <UIFormSelect
                    data-testid="visibility"
                    isReactHookForm
                    name="visibility"
                    label="Visibility"
                    showHelper={true}
                    options={visibilityData.codeList}
                    defaultValue={work.visibility ? work.visibility.id : ""}
                  />
                ) : (
                  <UICodedTermItem item={work.visibility} />
                )}
              </UIFormField>
            </div>
          </div>
          <div className="column one-third">
            <div className="box is-relative">
              <UIFormField label="Project Cycle">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-cycle"
                    isReactHookForm
                    placeholder="Project Cycle"
                    name="projectCycle"
                    label="Project Cycle"
                    defaultValue={projectCycle}
                  />
                ) : (
                  <p>{projectCycle}</p>
                )}
              </UIFormField>
              {PROJECT_METADATA.map((item) => {
                return (
                  <div key={item.name} data-testid={item.name}>
                    {isEditing ? (
                      <UIFormFieldArray
                        required
                        name={item.name}
                        label={item.label}
                      />
                    ) : (
                      <UIFormFieldArrayDisplay
                        items={administrativeMetadata[item.name]}
                        label={item.label}
                      />
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </form>
    </FormProvider>
  );
};

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAdministrative;
