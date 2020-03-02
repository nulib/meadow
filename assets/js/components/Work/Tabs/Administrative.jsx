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

const WorkTabsAdministrative = ({ work }) => {
  const [isEditing, setIsEditing] = useIsEditing();
  const { register, handleSubmit } = useForm();
  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      setIsEditing(false);
    }
  });

  const [addWorkToCollection] = useMutation(ADD_WORK_TO_COLLECTION, {
    onCompleted({ addWorkToCollection }) {
      setIsEditing(false);
      toastWrapper("is-success", "Work form has been updated");
    },
    refetchQueries(mutationResult) {
      return [{ query: GET_WORK, variables: { id: work.id } }];
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
      variables: { id: work.id, work: workUpdateInput }
    });
    // addWorkToCollection({
    //   variables: { workId: work.id, collectionId: data.collection }
    // });
  };

  const { data: collectionsData, loading, error } = useQuery(GET_COLLECTIONS);
  console.log(collectionsData);
  return (
    <form name="work-administrative-form" onSubmit={handleSubmit(onSubmit)}>
      <div className="columns is-centered">
        <div className="column is-two-thirds">
          <div className="box">
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
                  <p
                    className={`tag ${
                      work.visibility === "RESTRICTED"
                        ? "is-danger"
                        : "is-success"
                    }`}
                  >
                    {work.visibility}
                  </p>
                )}
              </div>
            </div>

            <div className="field">
              <label className="label">
                Collection <UITagNotYetSupported label="Work in Progress" />
              </label>
              <div className="control">
                {isEditing ? (
                  <div className="select">
                    <select
                      ref={register}
                      name="collection"
                      defaultValue={work.collection ? work.collection.id : ""}
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
                    {work.collection
                      ? work.collection.name
                      : "Not part of a collection"}
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
                        work.administrativeMetadata
                          ? work.administrativeMetadata.preservationLevel
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
                    {work.administrativeMetadata
                      ? work.administrativeMetadata.preservationLevel
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
                      defaultValue={
                        work.administrativeMetadata
                          ? work.administrativeMetadata.rightsStatement
                          : ""
                      }
                    >
                      <option value="">Select dropdown</option>
                      {RIGHTS_STATEMENTS.map(({ term, id }) => (
                        <option key={id} value={id}>
                          {`${term}`}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : (
                  <p>
                    {work.administrativeMetadata
                      ? work.administrativeMetadata.rightsStatement
                      : ""}
                  </p>
                )}
              </div>
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
                  className="button"
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
