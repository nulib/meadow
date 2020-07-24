import React from "react";
import PropTypes from "prop-types";
import { useQuery } from "@apollo/client";
import UITagNotYetSupported from "../../UI/TagNotYetSupported";
import UIInput from "../../UI/Form/Input";
import UIFormTextarea from "../../UI/Form/Textarea";
import UIFormField from "../../UI/Form/Field";
import UIFormSelect from "../../UI/Form/Select";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";

const BatchEditAboutCoreMetadata = ({ errors, register, ...restProps }) => {
  const {
    loading: rightsStatementsLoading,
    error: rightsStatementsError,
    data: rightsStatementsData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "RIGHTS_STATEMENT" },
  });
  const {
    loading: licenseLoading,
    error: licenseError,
    data: licenseData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "LICENSE" },
  });

  return (
    <div
      className="columns is-multiline"
      data-testid="core-metadata"
      {...restProps}
    >
      <div className="column is-half">
        {/* Title */}
        <UIFormField label="Title" required>
          <UIInput
            register={register}
            required
            name="title"
            label="Title"
            data-testid="title"
            errors={errors}
          />
        </UIFormField>
      </div>
      <div className="column is-half">
        {/* Description */}
        <UIFormField label="Description" required>
          <UIFormTextarea
            register={register}
            required
            name="description"
            label="Description"
            data-testid="description"
            errors={errors}
          />
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
        {/* License */}
        <UIFormField label="License">
          <UIFormSelect
            register={register}
            name="license"
            label="License"
            options={licenseData ? licenseData.codeList : []}
            errors={errors}
            data-testid="license"
            showHelper
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
