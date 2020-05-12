import React, { useState, useEffect } from "react";
import { useQuery } from "@apollo/react-hooks";
import PropTypes from "prop-types";
import { Link } from "react-router-dom";
import { toastWrapper } from "../../../services/helpers";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useForm } from "react-hook-form";
import { useMutation } from "@apollo/react-hooks";
import useIsEditing from "../../../hooks/useIsEditing";
import { GET_WORK, UPDATE_WORK } from "../work.query";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UIInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormSelect from "../../UI/Form/Select";
import UIControlledTermList from "../../UI/ControlledTerm/List";
import UICodedTermItem from "../../UI/CodedTerm/Item";
import WorkTabsHeader from "./Header";
import { CODE_LIST_QUERY } from "../controlledVocabulary.query.js";
import UIFormFieldArrayDisplay from "../../UI/Form/FieldArrayDisplay";
import UIPlaceholder from "../../UI/Placeholder";

const WorkTabsAbout = ({ work }) => {
  const { descriptiveMetadata } = work;
  const [showCoreMetadata, setShowCoreMetadata] = useState(true);
  const [showDescriptiveMetadata, setShowDescriptiveMetadata] = useState(true);
  const [isEditing, setIsEditing] = useIsEditing();

  // React hook form setup
  const { register, handleSubmit, errors, control, reset } = useForm({
    // Declare form "field array" fields here
    defaultValues: {
      abstract: descriptiveMetadata.abstract || [],
      alternateTitle: descriptiveMetadata.alternateTitle || [],
    },
  });

  useEffect(() => {
    // Tell React Hook Form to update field array form values when a Work updates
    reset({
      abstract: descriptiveMetadata.abstract,
      alternateTitle: descriptiveMetadata.alternateTitle,
    });
  }, [work]);

  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });

  const [updateWork, { loading: updateWorkLoading }] = useMutation(
    UPDATE_WORK,
    {
      onCompleted({ updateWork }) {
        toastWrapper("is-success", "Work form updated successfully");
      },
      refetchQueries: [{ query: GET_WORK, variables: { id: work.id } }],
      awaitRefetchQueries: true,
    }
  );

  const onSubmit = (data) => {
    const {
      abstract = [],
      alternateTitle = [],
      description = "",
      title = "",
    } = data;
    console.log("data", data);

    let workUpdateInput = {
      descriptiveMetadata: {
        abstract,
        alternateTitle,
        description,
        rightsStatement: {
          id: data.rightsStatement,
        },
        title,
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
          <div className="box is-relative">
            <UIPlaceholder isActive={updateWorkLoading} rows={10} />

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

                <UIFormField label="Rights Statement" notLive mocked>
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
                    <UICodedTermItem
                      item={descriptiveMetadata.rightsStatement}
                    />
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
          <div className="box is-relative">
            <UIPlaceholder isActive={updateWorkLoading} rows={10} />

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
              <div>
                {isEditing ? (
                  <UIFormFieldArray
                    register={register}
                    control={control}
                    required
                    name="abstract"
                    label="Abstract"
                    data-testid="fieldset-abstract"
                    errors={errors}
                  />
                ) : (
                  <UIFormFieldArrayDisplay
                    items={descriptiveMetadata.abstract}
                    label="Abstract"
                  />
                )}

                {isEditing ? (
                  <UIFormFieldArray
                    register={register}
                    control={control}
                    required
                    name="alternateTitle"
                    label="Alternate Title"
                    data-testid="fieldset-alternate-title"
                    errors={errors}
                  />
                ) : (
                  <UIFormFieldArrayDisplay
                    items={descriptiveMetadata.alternateTitle}
                    label="Alternate Title"
                  />
                )}

                <UIFormField label="Contributors" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList
                      items={descriptiveMetadata.contributor}
                    />
                  )}
                </UIFormField>

                <UIFormField label="Creators" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList items={descriptiveMetadata.creator} />
                  )}
                </UIFormField>

                <UIFormField label="Genre" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList items={descriptiveMetadata.genre} />
                  )}
                </UIFormField>

                <UIFormField label="License" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UICodedTermItem item={descriptiveMetadata.license} />
                  )}
                </UIFormField>

                <UIFormField label="Location" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList
                      items={descriptiveMetadata.location}
                    />
                  )}
                </UIFormField>

                <UIFormField label="Language" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList
                      items={descriptiveMetadata.language}
                    />
                  )}
                </UIFormField>

                <UIFormField label="Style Period" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList
                      items={descriptiveMetadata.stylePeriod}
                    />
                  )}
                </UIFormField>

                <UIFormField label="Subject" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList items={descriptiveMetadata.subject} />
                  )}
                </UIFormField>

                <UIFormField label="Technique" mocked notLive>
                  {isEditing ? (
                    <p>Form elements go here</p>
                  ) : (
                    <UIControlledTermList
                      items={descriptiveMetadata.technique}
                    />
                  )}
                </UIFormField>
              </div>
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
