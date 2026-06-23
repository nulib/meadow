import PropTypes from "prop-types";
import { RIGHTS_METADATA } from "@js/services/metadata";
import React from "react";
import UICodedTermItem from "@js/components/UI/CodedTerm/Item";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import UIFormInput from "@js/components/UI/Form/Input";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import UIFormSelect from "@js/components/UI/Form/Select";
import { useCodeLists } from "@js/context/code-list-context";
import {
  FieldProvenanceBadge,
  fieldProvenance,
} from "@js/components/AIProvenance/Badges";

const WorkTabsAboutRightsMetadata = ({
  descriptiveMetadata,
  isEditing,
  provenance = {},
}) => {
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
              isTextarea={item.inputEl && item.inputEl === "textarea"}
            />
          ) : (
            <>
              <UIFormFieldArrayDisplay
                values={descriptiveMetadata[item.name]}
                label={item.label}
              />
              <FieldProvenanceBadge
                entry={fieldProvenance(provenance, item.name)}
              />
            </>
          )}
        </div>
      ))}

      <div className="column is-half">
        {/* License */}
        <UIFormField label="License">
          {isEditing ? (
            <UIFormSelect
              isReactHookForm
              name="license"
              label="License"
              showHelper={true}
              data-testid="license"
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
            <>
              <UICodedTermItem item={descriptiveMetadata.license} />
              <FieldProvenanceBadge
                entry={fieldProvenance(provenance, "license")}
              />
            </>
          )}
        </UIFormField>
      </div>

      <div className="column is-half" data-testid="terms-of-use">
        <UIFormField label="Terms of Use">
          {isEditing ? (
            <UIFormTextarea
              isReactHookForm
              label="Terms of Use"
              name="termsOfUse"
              defaultValue={descriptiveMetadata.termsOfUse}
            />
          ) : (
            <>
              <p>{descriptiveMetadata.termsOfUse}</p>
              <FieldProvenanceBadge
                entry={fieldProvenance(provenance, "termsOfUse")}
              />
            </>
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutRightsMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
  provenance: PropTypes.object,
};

export default WorkTabsAboutRightsMetadata;
