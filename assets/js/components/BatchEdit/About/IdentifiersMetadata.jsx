import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
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
        <UIFormField label="Related URL">
          <UIFormRelatedURL
            codeLists={
              codeLists.relatedUrlData ? codeLists.relatedUrlData.codeList : []
            }
            label="Related URL"
            name="relatedUrl"
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutIdentifiersMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutIdentifiersMetadata;
