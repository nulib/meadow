import {
  RIGHTS_METADATA,
  getCodedTermSelectOptions,
} from "@js/services/metadata";

import PropTypes from "prop-types";
import React from "react";
import UIFormBatchFieldArray from "@js/components/UI/Form/BatchFieldArray";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import UIFormTextarea from "@js/components/UI/Form/Textarea";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAboutRightsMetadata = ({ ...restProps }) => {
  const codeLists = useCodeLists();

  return (
    <div
      className="columns is-multiline"
      data-testid="rights-metadata"
      {...restProps}
    >
      {RIGHTS_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormBatchFieldArray
            required
            name={item.name}
            label={item.label}
            isTextarea={item.inputEl && item.inputEl === "textarea"}
          />
        </div>
      ))}
      <div className="column is-three-quarters">
        <UIFormField label="License">
          <UIFormSelect
            isReactHookForm
            name="license"
            label="License"
            options={
              codeLists.licenseData
                ? getCodedTermSelectOptions(
                    codeLists.licenseData.codeList,
                    "LICENSE",
                  )
                : []
            }
            data-testid="license-select"
            showHelper
          />
        </UIFormField>
      </div>

      <div className="column is-half" data-testid="terms-of-use">
        <UIFormField label="Terms of Use">
          <UIFormTextarea
            isReactHookForm
            label="Terms of Use"
            name="termsOfUse"
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutRightsMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutRightsMetadata;
