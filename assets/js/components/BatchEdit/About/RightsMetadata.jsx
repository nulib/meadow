import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import UIFormSelect from "../../UI/Form/Select";
import { RIGHTS_METADATA } from "../../../services/metadata";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";
import { useQuery } from "@apollo/client";
import UIFormField from "../../UI/Form/Field";

const BatchEditAboutRightsMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
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
      data-testid="rights-metadata"
      {...restProps}
    >
      {RIGHTS_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormFieldArray
            register={register}
            control={control}
            required
            name={item.name}
            label={item.label}
            errors={errors}
          />
        </div>
      ))}
      <div className="column is-three-quarters">
        {/* License */}
        <UIFormField label="License" data-testid="license">
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

BatchEditAboutRightsMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutRightsMetadata;
