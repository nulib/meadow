import React, { useEffect } from "react";
import PropTypes from "prop-types";
import { useQuery, useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { toastWrapper } from "../../../services/helpers";
import { GET_COLLECTIONS } from "../../Collection/collection.query";
import { UPDATE_WORK, GET_WORK } from "../work.query";
import { useForm } from "react-hook-form";
import { Link } from "react-router-dom";
import UIFormSelect from "../../UI/Form/Select";
import UIFormField from "../../UI/Form/Field";
import WorkTabsHeader from "./Header";
import { CODE_LIST_QUERY } from "../controlledVocabulary.query.js";
import UICodedTermItem from "../../UI/CodedTerm/Item";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormInput from "../../UI/Form/Input.jsx";
import UIFormFieldArrayDisplay from "../../UI/Form/FieldArrayDisplay";
import UIPlaceholder from "../../UI/Placeholder";

const WorkTabsAdministrative = ({ work }) => {
  const { id, administrativeMetadata, collection, project, sheet } = work;
  const {
    status,
    preservationLevel,
    projectName = [],
    projectDesc = [],
    projectProposer = [],
    projectManager = [],
    projectTaskNumber = [],
    projectCycle,
  } = administrativeMetadata;
  const [isEditing, setIsEditing] = useIsEditing();

  const {
    data: collectionsData,
    loading: collectionsLoading,
    error: collectionsError,
  } = useQuery(GET_COLLECTIONS);

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

  const { register, handleSubmit, errors, control, reset } = useForm({});

  useEffect(() => {
    reset({
      projectName,
      projectDesc,
      projectProposer,
      projectManager,
      projectTaskNumber,
      projectCycle,
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
    const {
      status,
      preservationLevel,
      projectName = [],
      projectDesc = [],
      projectProposer = [],
      projectManager = [],
      projectTaskNumber = [],
      projectCycle,
      collection,
      visibility,
    } = data;
    let workUpdateInput = {
      administrativeMetadata: {
        preservationLevel: { id: preservationLevel },
        status: { id: status },
        projectName,
        projectDesc,
        projectProposer,
        projectManager,
        projectTaskNumber,
        projectCycle,
      },
      collectionId: collection,
      visibility: visibility,
    };
    updateWork({
      variables: { id, work: workUpdateInput },
    });
  };

  if (
    collectionsLoading ||
    preservationLevelsLoading ||
    statusLoading ||
    visibilityLoading
  ) {
    return null;
  }

  if (
    collectionsError ||
    preservationLevelsError ||
    statusError ||
    visibilityError
  ) {
    return (
      <p className="notification is-danger">
        There was an error loading GraphQL data on the Work Administrative tab
      </p>
    );
  }

  return (
    <form name="work-administrative-form" onSubmit={handleSubmit(onSubmit)}>
      <WorkTabsHeader title="Administrative Metadata">
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
      </WorkTabsHeader>

      <div className="columns">
        <div className="column is-two-thirds">
          <div className="box is-relative">
            <UIPlaceholder isActive={updateWorkLoading} rows={10} />
            <UIFormField label="Collection">
              {isEditing ? (
                <UIFormSelect
                  register={register}
                  required
                  name="collection"
                  label="Collection"
                  options={collectionsData.collections.map((collection) => ({
                    id: collection.id,
                    value: collection.id,
                    label: collection.name,
                  }))}
                  defaultValue={collection ? collection.id : ""}
                  errors={errors}
                />
              ) : (
                <p>
                  {collection ? collection.name : "Not part of a collection"}
                </p>
              )}
            </UIFormField>

            <UIFormField label="Preservation Level" mocked notLive>
              {isEditing ? (
                <UIFormSelect
                  register={register}
                  name="preservationLevel"
                  label="Preservation Level"
                  options={preservationLevelsData.codeList}
                  defaultValue={preservationLevel ? preservationLevel.id : ""}
                  errors={errors}
                />
              ) : (
                <p>
                  {preservationLevel
                    ? preservationLevel.label
                    : "None selected"}
                </p>
              )}
            </UIFormField>

            <UIFormField label="Status" mocked notLive>
              {isEditing ? (
                <UIFormSelect
                  register={register}
                  name="status"
                  label="Status"
                  options={statusData.codeList}
                  defaultValue={status ? status.id : ""}
                  errors={errors}
                />
              ) : (
                <p>{status ? status.label : "None selected"}</p>
              )}
            </UIFormField>

            <UIFormField label="Themes" mocked notLive>
              <p>Nothing yet</p>
            </UIFormField>

            <UIFormField label="Visibility" mocked notLive>
              {isEditing ? (
                <UIFormSelect
                  register={register}
                  required
                  name="visibility"
                  label="Visibility"
                  options={visibilityData.codeList}
                  defaultValue={work.visibility ? work.visibility.id : ""}
                  errors={errors}
                />
              ) : (
                <UICodedTermItem item={work.visibility} />
              )}
            </UIFormField>
          </div>
        </div>
        <div className="column one-third">
          <div className="box is-relative">
            <UIPlaceholder isActive={updateWorkLoading} rows={10} />
            <UIFormField label="Project">
              <Link to={`/project/${project.id}`}>{project.name}</Link>
            </UIFormField>

            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name="projectName"
                label="Project Name"
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={projectName}
                label="Project Name"
              />
            )}
            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name="projectDesc"
                label="Project Description"
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={projectDesc}
                label="Project Description"
              />
            )}

            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name="projectProposer"
                label="Project Proposer"
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={projectProposer}
                label="Project Proposer"
              />
            )}

            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name="projectManager"
                label="Project Manager"
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={projectManager}
                label="Project Manager"
              />
            )}

            {isEditing ? (
              <UIFormFieldArray
                register={register}
                control={control}
                required
                name="projectTaskNumber"
                label="Project Task Number"
                errors={errors}
              />
            ) : (
              <UIFormFieldArrayDisplay
                items={projectTaskNumber}
                label="Project Task Number"
              />
            )}

            <UIFormField label="Project Cycle">
              {isEditing ? (
                <UIFormInput
                  placeholder="Project Cycle"
                  register={register}
                  required
                  name="projectCycle"
                  label="Project Cycle"
                  errors={errors}
                  defaultValue={projectCycle}
                />
              ) : (
                <p>{projectCycle}</p>
              )}
            </UIFormField>

            <UIFormField label="Ingest Sheet">
              <Link to={`/project/${project.id}/ingest-sheet/${sheet.id}`}>
                {sheet.name}
              </Link>
            </UIFormField>
          </div>
        </div>
      </div>
    </form>
  );
};

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAdministrative;
