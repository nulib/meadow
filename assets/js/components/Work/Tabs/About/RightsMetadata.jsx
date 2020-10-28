import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import { RIGHTS_METADATA } from "../../../../services/metadata";
import UIFormField from "../../../UI/Form/Field";
import UIFormInput from "../../../UI/Form/Input";
import UIFormSelect from "../../../UI/Form/Select";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { useCodeLists } from "@js/context/code-list-context";

const WorkTabsAboutRightsMetadata = ({ descriptiveMetadata, isEditing }) => {
  const codeLists = useCodeLists();

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

      <div className="column is-half" data-testid="license">
        {/* License */}
        <UIFormField label="License">
          {isEditing ? (
            <UIFormSelect
              name="license"
              showHelper={true}
              label="License"
              options={
                codeLists.licenseData ? codeLists.licenseData.codeList : []
              }
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

      <div className="column is-half" data-testid="input-terms-of-use">
        <UIFormField label="Terms of Use">
          {isEditing ? (
            <UIFormInput
              isReactHookForm
              label="Terms of Use"
              name="termsOfUse"
              defaultValue={descriptiveMetadata.termsOfUse}
            />
          ) : (
            <p>{descriptiveMetadata.termsOfUse || "No value"}</p>
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
