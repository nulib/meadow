import React from "react";
import PropTypes from "prop-types";
import { useQuery, useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { toastWrapper } from "../../../services/helpers";
import { GET_COLLECTIONS } from "../../Collection/collection.query";
import { UPDATE_WORK, ADD_WORK_TO_COLLECTION, GET_WORK } from "../work.query";
import { useForm } from "react-hook-form";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import { Link } from "react-router-dom";
import UIFormSelect from "../../UI/Form/Select";
import UIFormField from "../../UI/Form/Field";
import WorkTabsHeader from "./Header";
import { CODE_LIST_QUERY } from "../controlledVocabulary.query.js";
import { setVisibilityClass } from "../../../services/helpers";

const WorkTabsAdministrative = ({ work }) => {
  const { id, administrativeMetadata, collection, project, sheet } = work;
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit, errors } = useForm();
  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
    },
  });
  const {
    loading: preservationLevelsLoading,
    error: preservationLevelsError,
    data: preservationLevelsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "PRESERVATION_LEVEL" },
  });
  const {
    loading: visibilityLoading,
    error: visibilityError,
    data: visibilityData,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "VISIBILITY" } });

  // TODO: Add Work to collection is disrupting changes made using updateWork,
  // need to verify apolloclient update/rollback options upon adding collection to work.
  const [addWorkToCollection] = useMutation(ADD_WORK_TO_COLLECTION, {
    onCompleted({ addWorkToCollection }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work form has been updated");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_WORK, variables: { id } }];
    },
  });

  const onSubmit = (data) => {
    let workUpdateInput = {
      administrativeMetadata: {
        preservationLevel: { id: Number(data.preservationLevel) },
      },
      visibility: data.visibility,

      published: true,
    };
    updateWork({
      variables: { id, work: workUpdateInput },
    });
    addWorkToCollection({
      variables: { workId: work.id, collectionId: data.collection },
    });
  };

  const { data: collectionsData, loading, error } = useQuery(GET_COLLECTIONS);
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
          <div className="box">
            <UIFormField label="Visibility">
              <UITagNotYetSupported label="Data is mocked" />
              <UITagNotYetSupported label="Update not yet supported" />
              {isEditing ? (
                <UIFormSelect
                  register={register}
                  required
                  name="visibility"
                  label="Visibility"
                  options={visibilityData.codeList}
                  defaultValue={work.visibility && work.visibility.id}
                  errors={errors}
                />
              ) : (
                work.visibility && (
                  <p
                    className={`tag ${setVisibilityClass(work.visibility.id)}`}
                  >
                    {work.visibility.label.toUpperCase()}
                  </p>
                )
              )}
            </UIFormField>

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

            <UIFormField label="Themes">
              <UITagNotYetSupported label="Display not yet supported" />
              <UITagNotYetSupported label="Update not yet supported" />
            </UIFormField>

            <UIFormField label="Preservation Level">
              <UITagNotYetSupported label="Data is mocked" />
              <UITagNotYetSupported label="Update not yet supported" />
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
                  {administrativeMetadata
                    ? administrativeMetadata.preservationLevel.label
                    : "None selected"}
                </p>
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
