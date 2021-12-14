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
import usePassedInSearchTerm from "@js/hooks/usePassedInSearchTerm";

const WorkTabsAdministrative = ({ work }) => {
  const {
    id,
    administrativeMetadata,
    collection,
    ingestSheet,
    project,
    published,
    readingRoom,
    visibility,
    insertedAt,
    updatedAt,
  } = work;
  const [isEditing, setIsEditing] = useIsEditing();
  const methods = useForm();
  const { handleFacetLinkClick } = useFacetLinkClick();
  const { handlePassedInSearchTerm } = usePassedInSearchTerm();

  const [updateWork, { loading: updateWorkLoading, error: updateWorkError }] =
    useMutation(UPDATE_WORK, {
      onCompleted({ updateWork }) {
        setIsEditing(false);
        toastWrapper("is-success", "Work form updated successfully");
      },
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    });
  const {
    projectCycle,
    projectDesc,
    projectManager,
    projectName,
    projectProposer,
    projectTaskNumber,
  } = administrativeMetadata;

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
      readingRoom: currentFormValues.readingRoom,
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
                readingRoom={readingRoom}
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
                  <Button
                    isText
                    data-testid="view-project-works"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("IngestProject", project.title)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{project.title}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Ingest Sheet">
                {project && ingestSheet ? (
                  <Button
                    isText
                    data-testid="view-ingest-sheet-works"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("IngestSheet", ingestSheet.title)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{ingestSheet.title}</span>
                  </Button>
                ) : null}
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
                ) : projectCycle ? (
                  <Button
                    isText
                    data-testid="project-cycle-link"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("ProjectCycle", projectCycle)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectCycle}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Project / Job Name">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-name"
                    isReactHookForm
                    placeholder="Project Name"
                    name="projectName"
                    label="Project Name"
                    defaultValue={projectName}
                  />
                ) : projectName.length > 0 ? (
                  <Button
                    isText
                    data-testid="project-name-link"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("ProjectName", projectName)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectName}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Project / Job Description">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-description"
                    isReactHookForm
                    placeholder="Project Description"
                    name="projectDescription"
                    label="Project Description"
                    defaultValue={projectDesc}
                  />
                ) : projectDesc.length > 0 ? (
                  <Button
                    isText
                    data-testid="project-description-link"
                    className="break-word"
                    onClick={() =>
                      handlePassedInSearchTerm(
                        "administrativeMetadata.projectDesc",
                        projectDesc || null
                      )
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectDesc}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Project / Job Manager">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-manager"
                    isReactHookForm
                    placeholder="Project Manager"
                    name="projectManager"
                    label="Project Manager"
                    defaultValue={projectManager}
                  />
                ) : projectManager.length > 0 ? (
                  <Button
                    isText
                    data-testid="project-manager-link"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("ProjectManager", projectManager)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectManager}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Project / Job Proposer">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-proposer"
                    isReactHookForm
                    placeholder="Project Proposer"
                    name="projectProposer"
                    label="Project Proposer"
                    defaultValue={projectProposer}
                  />
                ) : projectProposer.length > 0 ? (
                  <Button
                    isText
                    data-testid="project-proposer-link"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick("ProjectProposer", projectProposer)
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectProposer}</span>
                  </Button>
                ) : null}
              </UIFormField>

              <UIFormField label="Project / Job Tasker Number">
                {isEditing ? (
                  <UIFormInput
                    data-testid="project-task-number"
                    isReactHookForm
                    placeholder="Project Task Number"
                    name="projectTaskNumber"
                    label="Project Task Number"
                    defaultValue={projectTaskNumber}
                  />
                ) : projectTaskNumber.length > 0 ? (
                  <Button
                    isText
                    data-testid="project-task-number-link"
                    className="break-word"
                    onClick={() =>
                      handleFacetLinkClick(
                        "ProjectTaskNumber",
                        projectTaskNumber
                      )
                    }
                    css={{ padding: "0", textTransform: "none !important" }}
                  >
                    <span>{projectTaskNumber}</span>
                  </Button>
                ) : null}
              </UIFormField>

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
