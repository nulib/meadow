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

const BatchEditAboutCoreMetadata = ({ ...restProps }) => {
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
            isReactHookForm
            name="title"
            label="Title"
            data-testid="title"
          />
        </UIFormField>
      </div>

      <div className="column is-full">
        {/* Alternate Title */}
        <UIFormFieldArray
          name="alternateTitle"
          data-testid="alternate-title"
          label="Alternate Title"
          className="add"
        />
      </div>
      <div className="column is-half">
        {/* Date Created */}
        <UIFormField label="Date Created" notLive>
          <UIInput
            isReactHookForm
            name="dateCreated"
            label="Date Created"
            type="date"
            data-testid="date-created"
          />
          <UITagNotYetSupported label="Display not yet supported" />
          <UITagNotYetSupported label="Update not yet supported" />
        </UIFormField>
      </div>
      <div className="column is-half">
        <UIFormField label="Rights Statement">
          <UIFormSelect
            isReactHookForm
            name="rightsStatement"
            label="Rights Statement"
            options={rightsStatementsData ? rightsStatementsData.codeList : []}
            data-testid="rights-statement"
            showHelper
          />
        </UIFormField>
      </div>
      <div className="column is-full">
        {/* Description */}
        <UIFormField label="Description">
          <UIFormTextarea
            isReactHookForm
            name="description"
            label="Description"
            data-testid="description"
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutCoreMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutCoreMetadata;
