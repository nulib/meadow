import React from "react";
import PropTypes from "prop-types";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import {
  RIGHTS_METADATA,
  getCodedTermSelectOptions,
} from "@js/services/metadata";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormSelect from "@js/components/UI/Form/Select";
import UICodedTermItem from "@js/components/UI/CodedTerm/Item";
import { useCodeLists } from "@js/context/code-list-context";

const WorkTabsAboutRightsMetadata = ({ descriptiveMetadata, isEditing }) => {
  const codeLists = useCodeLists();

  return (
    <div className="columns is-multiline" data-testid="rights-metadata">
      {RIGHTS_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray 
              required 
              name={item.name} 
              label={item.label}
              isTextarea={item.inputEl && item.inputEl === 'textarea'} 
              />
          ) : (
            <UIFormFieldArrayDisplay
              values={descriptiveMetadata[item.name]}
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
              isReactHookForm
              showHelper={true}
              label="License"
              options={
                codeLists.licenseData
                  ? getCodedTermSelectOptions(
                      codeLists.licenseData.codeList,
                      "LICENSE"
                    )
                  : []
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
            <p>{descriptiveMetadata.termsOfUse}</p>
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
