import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormBatchFieldArray from "../../UI/Form/BatchFieldArray";
import { IDENTIFIER_METADATA } from "../../../services/metadata";
import { useQuery } from "@apollo/client";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";
import UISkeleton from "../../UI/Skeleton";
import UIError from "../../UI/Error";
import UIFormRelatedURL from "../../UI/Form/RelatedURL";

const BatchEditAboutIdentifiersMetadata = ({ ...restProps }) => {
  const { data: relatedUrlData, loading, relatedUrlErrors } = useQuery(
    CODE_LIST_QUERY,
    {
      variables: { scheme: "RELATED_URL" },
    }
  );
  if (loading) return <UISkeleton rows={20} />;
  if (relatedUrlErrors)
    return (
      <div>
        <UIError error={relatedUrlErrors} />
      </div>
    );
  if (!relatedUrlData) {
    return (
      <div>
        <UIError error={{ message: "No Related URL data" }} />
      </div>
    );
  }
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
            codeLists={relatedUrlData.codeList}
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
