import React from "react";
import PropTypes from "prop-types";
import { useQuery, useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { toastWrapper } from "../../../services/helpers";
import {
  VISIBILITY_OPTIONS,
  RIGHTS_STATEMENTS,
  PRESERVATION_LEVELS
} from "../../../services/global-vars";
import { GET_COLLECTIONS } from "../../Collection/collection.query";
import { UPDATE_WORK, ADD_WORK_TO_COLLECTION, GET_WORK } from "../work.query";
import { useForm } from "react-hook-form";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import { Link } from "react-router-dom";
import { setVisibilityClass } from "../../../services/helpers";

const WorkTabsAdministrative = ({ work }) => {
  const { id, administrativeMetadata, collection, project, sheet } = work;
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit } = useForm();
  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
    }
  });

  // TODO: Add Work to collection is disrupting changes made using updateWork,
  // need to verify apolloclient update/rollback options upon adding collection to work.
  const [addWorkToCollection] = useMutation(ADD_WORK_TO_COLLECTION, {
    onCompleted({ addWorkToCollection }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work form has been updated");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_WORK, variables: { id } }];
    }
  });

  const onSubmit = data => {
    let workUpdateInput = {
      administrativeMetadata: {
        preservationLevel: Number(data.preservationLevel),
        rightsStatement: data.rightsStatement
      },
      visibility: data.visibility,

      published: true
    };
    updateWork({
      variables: { id, work: workUpdateInput }
    });
    addWorkToCollection({
      variables: { workId: work.id, collectionId: data.collection }
    });
  };

  const { data: collectionsData, loading, error } = useQuery(GET_COLLECTIONS);
  return (
    <form name="work-administrative-form" onSubmit={handleSubmit(onSubmit)}>
      <div className="columns is-centered">
        <div className="column is-two-thirds">
          <div className="box is-shadowless">
            <div className="field">
              <label className="label">Visibility</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="visibility"
                      defaultValue={work.visibility}
                    >
                      <option value="">Select option</option>
                      {VISIBILITY_OPTIONS.map(({ label, value }) => (
                        <option key={value} value={value}>
                          {`${value} (${label})`}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : (
                  <p className={`tag ${setVisibilityClass(work.visibility)}`}>
                    {work.visibility.toUpperCase()}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Collection</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="collection"
                      defaultValue={collection ? collection.id : ""}
                    >
                      <option value="">Select dropdown</option>
                      {collectionsData.collections &&
                        collectionsData.collections.map(({ name, id }) => (
                          <option key={id} value={id}>
                            {`${name}`}
                          </option>
                        ))}
                    </select>
                  </div>
                ) : (
                  <p>
                    {collection ? collection.name : "Not part of a collection"}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">
                Themes{" "}
                <UITagNotYetSupported label="Display not yet supported" />
                <UITagNotYetSupported label="Update not yet supported" />
              </label>
            </div>

            <div className="field">
              <label className="label">Preservation Level</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="preservationLevel"
                      defaultValue={
                        administrativeMetadata
                          ? administrativeMetadata.preservationLevel
                          : ""
                      }
                    >
                      {PRESERVATION_LEVELS.map(({ label, id }) => (
                        <option key={id} value={id}>
                          {` ${label}`}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : (
                  <p>
                    {administrativeMetadata
                      ? administrativeMetadata.preservationLevel
                      : ""}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Rights Statement</label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="rightsStatement"
                      defaultValue={administrativeMetadata.rightsStatement}
                    >
                      <option value="">Select dropdown</option>
                      {RIGHTS_STATEMENTS.map(({ label, id }) => (
                        <option key={id} value={id}>
                          {`${label}`}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : (
                  <p>
                    {administrativeMetadata
                      ? administrativeMetadata.rightsStatement
                      : ""}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">Project</label>
              <Link to={`/project/${project.id}`}>{project.name}</Link>
            </div>
            <div className="field">
              <label className="label">Ingest Sheet</label>
              <Link to={`/project/${project.id}/ingest-sheet/${sheet.id}`}>
                {sheet.name}
              </Link>
            </div>
          </div>
        </div>
        <div className="column is-narrow">
          <div className="buttons is-right">
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
          </div>
        </div>
      </div>
    </form>
  );
};

WorkTabsAdministrative.propTypes = {
  work: PropTypes.object
};

export default WorkTabsAdministrative;
