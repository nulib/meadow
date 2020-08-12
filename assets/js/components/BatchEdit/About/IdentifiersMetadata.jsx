import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormFieldArray from "../../UI/Form/FieldArray";
import { IDENTIFIER_METADATA } from "../../../services/metadata";
import { useQuery } from "@apollo/client";
import { CODE_LIST_QUERY } from "../../Work/controlledVocabulary.gql.js";
import UISkeleton from "../../UI/Skeleton";
import UIError from "../../UI/Error";
import UIFormRelatedURL from "../../UI/Form/RelatedURL";

const BatchEditAboutIdentifiersMetadata = ({
  control,
  errors,
  register,
  ...restProps
}) => {
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
      <div className="column is-full" data-testid="relatedUrl">
        <UIFormField label="Related URL">
          <UIFormRelatedURL
            codeLists={relatedUrlData.codeList}
            control={control}
            errors={errors}
            label="Related URL"
            name="relatedUrl"
            register={register}
          />
        </UIFormField>
      </div>
    </div>
  );
};

BatchEditAboutIdentifiersMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  errors: PropTypes.object,
  register: PropTypes.func.isRequired,
  restProps: PropTypes.object,
};

export default BatchEditAboutIdentifiersMetadata;
