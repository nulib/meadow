import React from "react";
import PropTypes from "prop-types";
import UIFormBatchFieldArray from "@js/components/UI/Form/BatchFieldArray";
import UIFormSelect from "@js/components/UI/Form/Select";
import {
  RIGHTS_METADATA,
  getCodedTermSelectOptions,
} from "@js/services/metadata";
import UIFormField from "@js/components/UI/Form/Field";
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
          <UIFormBatchFieldArray required name={item.name} label={item.label} />
        </div>
      ))}
      <div className="column is-three-quarters">
        {/* License */}
        <UIFormField label="License">
          <UIFormSelect
            isReactHookForm
            name="license"
            label="License"
            options={
              codeLists.licenseData
                ? getCodedTermSelectOptions(
                    codeLists.licenseData.codeList,
                    "LICENSE"
                  )
                : []
            }
            data-testid="license-select"
            showHelper
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
