import React, { useState } from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UIInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormSelect from "../../UI/Form/Select";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";

const BatchEditAboutCoreMetadata = ({
  errors,
  control,
  register,
  ...restProps
}) => {
  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });

  return (
    <div
      className="columns is-multiline"
      data-testid="core-metadata"
      {...restProps}
    >
      <div className="column is-full">
        {/* Title */}
        <UIFormField label="Title">
          <UIInput
            register={register}
            name="title"
            label="Title"
            data-testid="title"
            errors={errors}
          />
        </UIFormField>
      </div>

      <div className="column is-full">
        {/* Alternate Title */}
        <UIFormFieldArray
          register={register}
          control={control}
          name="alternateTitle"
          data-testid="alternate-title"
          label="Alternate Title"
          errors={errors}
          className="add"
        />
      </div>
      <div className="column is-half">
        {/* Date Created */}
        <UIFormField label="Date Created" notLive>
          <UIInput
            register={register}
            name="dateCreated"
            label="Date Created"
            type="date"
            data-testid="date-created"
            errors={errors}
          />
          <UITagNotYetSupported label="Display not yet supported" />
          <UITagNotYetSupported label="Update not yet supported" />
        </UIFormField>
      </div>
      <div className="column is-half">
        <UIFormField label="Rights Statement">
          <UIFormSelect
            register={register}
            name="rightsStatement"
            label="Rights Statement"
            options={rightsStatementsData ? rightsStatementsData.codeList : []}
            errors={errors}
            data-testid="rights-statement"
            showHelper
          />
        </UIFormField>
      </div>
      <div className="column is-full">
        {/* Description */}
        <UIFormField label="Description">
          <UIFormTextarea
            register={register}
            name="description"
            label="Description"
            data-testid="description"
            errors={errors}
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutCoreMetadata.propTypes = {
  errors: PropTypes.object,
  register: PropTypes.func,
  restProps: PropTypes.object,
};

export default BatchEditAboutCoreMetadata;
