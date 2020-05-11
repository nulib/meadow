import React from "react";
import PropTypes from "prop-types";
import { useQuery, useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { toastWrapper } from "../../../services/helpers";
import { GET_COLLECTIONS } from "../../Collection/collection.query";
import { UPDATE_WORK, ADD_WORK_TO_COLLECTION, GET_WORK } from "../work.query";
import { useForm } from "react-hook-form";
import { Link } from "react-router-dom";
import UIFormSelect from "../../UI/Form/Select";
import UIFormField from "../../UI/Form/Field";
import WorkTabsHeader from "./Header";
import { CODE_LIST_QUERY } from "../controlledVocabulary.query.js";
import { setVisibilityClass } from "../../../services/helpers";
import UICodedTermItem from "../../UI/CodedTerm/Item";

const WorkTabsAdministrative = ({ work }) => {
  const { id, administrativeMetadata, collection, project, sheet } = work;
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit, errors } = useForm();

  const {
    data: collectionsData,
    loading: collectionsLoading,
    error: collectionsError,
  } = useQuery(GET_COLLECTIONS);

  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work Administrative data has been updated");
    },
  });

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
    let workUpdateInput = {
      administrativeMetadata: {
        preservationLevel: { id: data.preservationLevel },
        status: { id: data.status },
      },
      collectionId: data.collection,
      visibility: data.visibility,
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
          <div className="box content">
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
                  defaultValue={
                    administrativeMetadata
                      ? administrativeMetadata.preservationLevel.id
                      : ""
                  }
                  errors={errors}
                />
              ) : (
                <p>
                  {administrativeMetadata.preservationLevel
                    ? administrativeMetadata.preservationLevel.label
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
                  defaultValue={
                    administrativeMetadata.status
                      ? administrativeMetadata.status.id
                      : ""
                  }
                  errors={errors}
                />
              ) : (
                <p>
                  {administrativeMetadata
                    ? administrativeMetadata.status.label
                    : "None selected"}
                </p>
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
          <div className="box">
            <UIFormField label="Project">
              <Link to={`/project/${project.id}`}>{project.name}</Link>
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
