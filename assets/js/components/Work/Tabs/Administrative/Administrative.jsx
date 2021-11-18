import React, { useEffect } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/client";
import useIsEditing from "@js/hooks/useIsEditing";
import { toastWrapper } from "@js/services/helpers";
import { UPDATE_WORK, GET_WORK } from "@js/components/Work/work.gql.js";
import { useForm, FormProvider } from "react-hook-form";
import UIFormField from "@js/components/UI/Form/Field";
import UITabsStickyHeader from "@js/components/UI/Tabs/StickyHeader";
import UIFormInput from "@js/components/UI/Form/Input.jsx";
import UISkeleton from "@js/components/UI/Skeleton";
import { PROJECT_METADATA } from "@js/services/metadata";
import { Button, Notification } from "@nulib/design-system";
import WorkTabsAdministrativeGeneral from "@js/components/Work/Tabs/Administrative/General";
import WorkTabsAdministrativeCollection from "@js/components/Work/Tabs/Administrative/Collection";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import { formatDate } from "@js/services/helpers";
import { IconEdit } from "@js/components/Icon";

const WorkTabsAdministrative = ({ work }) => {
  const {
    id,
    administrativeMetadata,
    collection,
    ingestSheet,
    project,
    published,
    visibility,
    insertedAt,
    updatedAt,
  } = work;
  const [isEditing, setIsEditing] = useIsEditing();
  const methods = useForm();
  const { handleFacetLinkClick } = useFacetLinkClick();

  const [updateWork, { loading: updateWorkLoading, error: updateWorkError }] =
    useMutation(UPDATE_WORK, {
      onCompleted({ updateWork }) {
        setIsEditing(false);
        toastWrapper("is-success", "Work form updated successfully");
      },
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    });
  const { projectCycle } = administrativeMetadata;

  const onSubmit = (data) => {
    const currentFormValues = methods.getValues();
    const workUpdateInput = {
      administrativeMetadata: {
        libraryUnit: currentFormValues.libraryUnit
          ? { id: currentFormValues.libraryUnit, scheme: "LIBRARY_UNIT" }
          : {},
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
      workUpdateInput.administrativeMetadata[term.name] = [
        currentFormValues[term.name],
      ];
    }

    updateWork({
      variables: { id, work: workUpdateInput },
    });
  };

  const handleViewAllWorksClick = (collectionTitle) => {
    handleFacetLinkClick("Collection", collectionTitle);
  };

  if (updateWorkLoading) {
    <UISkeleton rows={10} />;
  }

  if (updateWorkError) {
    return (
      <Notification isDanger>
        There was an error loading GraphQL data on the Work Administrative tab
      </Notification>
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
              isPrimary
              onClick={() => setIsEditing(true)}
              data-testid="edit-button"
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
                data-testid="cancel-button"
                isText
                onClick={() => setIsEditing(false)}
              >
                Cancel
              </Button>
            </>
          )}
        </UITabsStickyHeader>

        <div className="columns">
          <div className="column is-half">
            <WorkTabsAdministrativeCollection
              collection={collection}
              handleViewAllWorksClick={handleViewAllWorksClick}
              isEditing={isEditing}
              workId={id}
            />

            <div className="box is-relative content">
              <h3>General</h3>
              <WorkTabsAdministrativeGeneral
                administrativeMetadata={administrativeMetadata}
                isEditing={isEditing}
                published={published}
                visibility={visibility}
              />
            </div>
          </div>
          <div className="column is-half">
            <div className="box is-relative">
              <div className="content">
                <h3>Project / Job Information</h3>
              </div>

              <UIFormField label="Ingest Project">
                {project ? (
                  <p>
                    <Button
                      isText
                      onClick={() =>
                        handleFacetLinkClick("Project", project.title || null)
                      }
                      data-testid="view-project-works"
                    >
                      {project.title || ""}
                    </Button>
                  </p>
                ) : null}
              </UIFormField>

              <UIFormField label="Ingest Sheet">
                <p>
                  {project && ingestSheet && (
                    <Button
                      isText
                      onClick={() =>
                        handleFacetLinkClick("IngestSheet", ingestSheet.title)
                      }
                      data-testid="view-ingest-sheet-works"
                    >
                      {ingestSheet.title}
                    </Button>
                  )}
                </p>
              </UIFormField>

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
                  <UIFormField
                    label={item.label}
                    key={item.name}
                    data-testid={item.name}
                  >
                    {isEditing ? (
                      <UIFormInput
                        isReactHookForm
                        // NOTE: Eventually Project data will come in as single values instead of an array
                        defaultValue={administrativeMetadata[item.name][0]}
                        label={item.label}
                        name={item.name}
                        placeholder={item.label}
                      />
                    ) : (
                      <p>{administrativeMetadata[item.name][0]}</p>
                    )}
                  </UIFormField>
                );
              })}
              <div className="field content">
                <p data-testid="inserted-at-label">
                  <strong>Work Created</strong>: {formatDate(insertedAt)}
                </p>
                <p data-testid="updated-at-label">
                  <strong>Last Modified</strong>: {formatDate(updatedAt)}
                </p>
              </div>
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
