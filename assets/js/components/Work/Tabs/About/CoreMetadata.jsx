import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import UITagNotYetSupported from "../../../UI/TagNotYetSupported";
import UIInput from "../../../UI/Form/Input";
import UIFormTextarea from "../../../UI/Form/Textarea";
import UIFormField from "../../../UI/Form/Field";
import UIFormSelect from "../../../UI/Form/Select";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql.js";

const WorkTabsAboutCoreMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  control,
}) => {
  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });

  return (
    <div className="columns is-multiline" data-testid="core-metadata">
      <div className="column is-full">
        {/* Title */}
        <UIFormField label="Title">
          {isEditing ? (
            <UIInput
              register={register}
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
      </div>
      <div className="column is-full">
        {/* Alternate Title */}
        {isEditing ? (
          <UIFormFieldArray
            register={register}
            control={control}
            name="alternateTitle"
            data-testid="alternate-title"
            label="Alternate Title"
            errors={errors}
          />
        ) : (
          <UIFormFieldArrayDisplay
            items={descriptiveMetadata.alternateTitle}
            label="Alternate Title"
          />
        )}
      </div>

      <div className="column is-half">
        {/* Date Created */}
        <UIFormField label="Date Created" notLive>
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
      <div className="column is-half">
        <UIFormField label="Rights Statement">
          {isEditing ? (
            <UIFormSelect
              register={register}
              name="rightsStatement"
              label="Rights Statement"
              showHelper={true}
              data-testid="rights-statement"
              options={
                rightsStatementsData ? rightsStatementsData.codeList : []
              }
              defaultValue={
                descriptiveMetadata.rightsStatement
                  ? descriptiveMetadata.rightsStatement.id
                  : ""
              }
              errors={errors}
            />
          ) : (
            <UICodedTermItem item={descriptiveMetadata.rightsStatement} />
          )}
        </UIFormField>
      </div>
      <div className="column is-full">
        {/* Description */}
        <UIFormField label="Description">
          {isEditing ? (
            <UIFormTextarea
              register={register}
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
      </div>
      {/* <div className="column is-half">
        License
        <UIFormField label="License">
          {isEditing ? (
            <UIFormSelect
              register={register}
              name="license"
              showHelper={true}
              label="License"
              options={licenseData ? licenseData.codeList : []}
              defaultValue={
                descriptiveMetadata.license
                  ? descriptiveMetadata.license.id
                  : ""
              }
              errors={errors}
            />
          ) : (
            <UICodedTermItem item={descriptiveMetadata.license} />
          )}
        </UIFormField>
      </div> */}
    </div>
  );
};

WorkTabsAboutCoreMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func,
};

export default WorkTabsAboutCoreMetadata;
