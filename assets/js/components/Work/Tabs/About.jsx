import React, { useState } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { UPDATE_WORK } from "../work.query";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UIInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormSelect from "../../UI/Form/Select";
import WorkTabsHeader from "./Header";
import { CODE_LIST_QUERY } from "../controlledVocabulary.query.js";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);

  // React hook form setup
  const { register, handleSubmit, watch, errors, control } = useForm({
    defaultValues: {
      imaMulti: [{ value: "New Ima Multi" }],
    },
  });

  const [isEditing, setIsEditing] = useIsEditing();
  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });

  const [updateWork] = useMutation(UPDATE_WORK, {
    onCompleted({ updateWork }) {
      toastWrapper("is-success", "Work form has been updated");
    },
  });

  const onSubmit = (data) => {
    const { description = "", title = "" } = data;
    let workUpdateInput = {
      descriptiveMetadata: {
        title,
        description,
        rightsStatement: {
          id: data.rightsStatement,
        },
      },
      published: true,
    };

    setIsEditing(false);
    updateWork({
      variables: { id: work.id, work: workUpdateInput },
    });
  };

  return (
    <form name="work-about-form" onSubmit={handleSubmit(onSubmit)}>
      <WorkTabsHeader title="Core and Descriptive Metadata">
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
      </WorkTabsHeader>

      <div className="columns">
        <div className="column is-half">
          <div className="box">
            <h2 className="title is-size-5">
              Core Metadata{" "}
              <a onClick={() => setShowCoreMetadata(!showCoreMetadata)}>
                <FontAwesomeIcon
                  icon={showCoreMetadata ? "chevron-down" : "chevron-right"}
                />
              </a>
            </h2>
            {showCoreMetadata && (
              <div>
                {/* Title */}
                <UIFormField label="Title">
                  {isEditing ? (
                    <UIInput
                      register={register}
                      required
                      name="title"
                      label="Title"
                      data-testid="title"
                      errors={errors}
                      defaultValue={descriptiveMetadata.title}
                    />
                  ) : (
                    <p>{descriptiveMetadata.title || "No value"}</p>
                  )}
                </UIFormField>

                {/* Test form field array element */}
                {isEditing ? (
                  <UIFormFieldArray
                    register={register}
                    control={control}
                    required
                    name="imaMulti"
                    label="Ima Multi"
                    data-testid="fieldset-ima-multi"
                    errors={errors}
                  />
                ) : (
                  <div className="field">
                    <label className="label">Ima Multi</label>
                    <UITagNotYetSupported label="Display not yet supported" />
                    <UITagNotYetSupported label="Update not yet supported" />
                  </div>
                )}

                {/* Description */}
                <UIFormField label="Description">
                  {isEditing ? (
                    <UIFormTextarea
                      register={register}
                      required
                      name="description"
                      label="Description"
                      data-testid="description"
                      errors={errors}
                      defaultValue={descriptiveMetadata.description}
                    />
                  ) : (
                    <p>{descriptiveMetadata.description || "No value"}</p>
                  )}
                </UIFormField>

                <UIFormField label="Rights Statement">
                  {isEditing ? (
                    <UIFormSelect
                      register={register}
                      name="rightsStatement"
                      label="Rights Statement"
                      options={
                        rightsStatementsData
                          ? rightsStatementsData.codeList
                          : []
                      }
                      defaultValue={descriptiveMetadata.rightsStatement.id}
                      errors={errors}
                    />
                  ) : (
                    <>
                      <UITagNotYetSupported label="Data is mocked" />
                      <UITagNotYetSupported label="Update not yet supported" />
                      <p>
                        {descriptiveMetadata
                          ? descriptiveMetadata.rightsStatement.label
                          : "None selected"}
                      </p>
                    </>
                  )}
                </UIFormField>

                {/* Date Created */}
                <UIFormField label="Date Created" isEditing={isEditing}>
                  {isEditing ? (
                    <UIInput
                      register={register}
                      name="dateCreated"
                      label="Date Created"
                      type="date"
                      data-testid="date-created"
                      errors={errors}
                      defaultValue={descriptiveMetadata.dateCreated}
                    />
                  ) : (
                    <>
                      <UITagNotYetSupported label="Display not yet supported" />
                      <UITagNotYetSupported label="Update not yet supported" />
                    </>
                  )}
                </UIFormField>
              </div>
            )}
          </div>
        </div>
        <div className="column is-half">
          <div className="box">
            <h2 className="title is-size-5">
              Descriptive Metadata{" "}
              <a
                onClick={() =>
                  setShowDescriptiveMetadata(!showDescriptiveMetadata)
                }
              >
                <FontAwesomeIcon
                  icon={
                    showDescriptiveMetadata ? "chevron-down" : "chevron-right"
                  }
                />
              </a>
            </h2>
            {showDescriptiveMetadata && (
              <>
                <UIFormField label="Creators">
                  <UITagNotYetSupported label="Display not yet supported" />{" "}
                  <UITagNotYetSupported label="Update not yet supported" />
                  <ul>
                    <li>
                      <Link to="/">Creator 1 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Creator 2 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Creator 3 as a link</Link>
                    </li>
                  </ul>
                </UIFormField>

                <UIFormField label="Contributors">
                  <UITagNotYetSupported label="Display not yet supported" />{" "}
                  <UITagNotYetSupported label="Update not yet supported" />
                  <ul>
                    <li>
                      <Link to="/">Contributor 1 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Contributor 2 as a link</Link>
                    </li>
                    <li>
                      <Link to="/">Contributor 3 as a link</Link>
                    </li>
                  </ul>
                </UIFormField>

                <UIFormField label="Genre">
                  <UITagNotYetSupported label="Data is mocked" />{" "}
                  <UITagNotYetSupported label="Update not yet supported" />
                  {descriptiveMetadata.genre &&
                    descriptiveMetadata.genre.length > 0 && (
                      <ul>
                        {descriptiveMetadata.genre.map((genre) => {
                          return (
                            <li key={genre.id}>
                              <a href={genre.id}>{genre.label}</a>
                            </li>
                          );
                        })}
                      </ul>
                    )}
                </UIFormField>
              </>
            )}
          </div>
        </div>
      </div>
    </form>
  );
};

WorkTabsAbout.propTypes = {
  work: PropTypes.object,
};

export default WorkTabsAbout;
