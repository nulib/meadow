import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import { RIGHTS_METADATA } from "../../../../services/metadata";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql";
import { useQuery } from "@apollo/client";
import UIFormField from "../../../UI/Form/Field";
import UIFormSelect from "../../../UI/Form/Select";
import UICodedTermItem from "../../../UI/CodedTerm/Item";

const WorkTabsAboutRightsMetadata = ({ descriptiveMetadata, isEditing }) => {
  const {
    loading: licenseLoading,
    error: licenseError,
    data: licenseData,
  } = useQuery(CODE_LIST_QUERY, {
    variables: { scheme: "LICENSE" },
  });
  return (
    <div className="columns is-multiline" data-testid="rights-metadata">
      {RIGHTS_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray required name={item.name} label={item.label} />
          ) : (
            <UIFormFieldArrayDisplay
              items={descriptiveMetadata[item.name]}
              label={item.label}
            />
          )}
        </div>
      ))}
      <div className="column is-three-quarters" data-testid="license">
        {/* License */}
        <UIFormField label="License">
          {isEditing ? (
            <UIFormSelect
              name="license"
              showHelper={true}
              label="License"
              options={licenseData ? licenseData.codeList : []}
              defaultValue={
                descriptiveMetadata.license
                  ? descriptiveMetadata.license.id
                  : ""
              }
            />
          ) : (
            <UICodedTermItem item={descriptiveMetadata.license} />
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutRightsMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
};

export default WorkTabsAboutRightsMetadata;
