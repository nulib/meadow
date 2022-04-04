import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import UIFormBatchFieldArray from "../../UI/Form/BatchFieldArray";
import { IDENTIFIER_METADATA } from "../../../services/metadata";
import UIFormRelatedURL from "../../UI/Form/RelatedURL";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAboutIdentifiersMetadata = ({ ...restProps }) => {
  const codeLists = useCodeLists();

  return (
    <div
      className="columns is-multiline"
      data-testid="identifiers-metadata"
      {...restProps}
    >
      {IDENTIFIER_METADATA.map((item) => (
        <div key={item.name} className="column is-half" data-testid={item.name}>
          <UIFormBatchFieldArray required name={item.name} label={item.label} />
        </div>
      ))}
      <div className="column is-full" data-testid="relatedUrl">
        <fieldset data-testid="batch-field-array">
          <legend data-testid="legend">Related URL</legend>
          <UIFormField label="Related URL">
            <UIFormRelatedURL
              codeLists={
                codeLists.relatedUrlData
                  ? codeLists.relatedUrlData.codeList
                  : []
              }
              label="Related URL"
              name="relatedUrl"
            />
            <UIFormSelect
              isReactHookForm
              name="relatedUrl--editType"
              data-testid="select-edit-type"
              options={[
                { id: "append", label: "Append values" },
                { id: "replace", label: "Replace existing values" },
                { id: "delete", label: "Delete all values" },
              ]}
            ></UIFormSelect>
          </UIFormField>
        </fieldset>
      </div>
    </div>
  );
};

BatchEditAboutIdentifiersMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutIdentifiersMetadata;
