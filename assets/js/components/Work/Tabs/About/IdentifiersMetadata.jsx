import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../../UI/Form/Field";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import { IDENTIFIER_METADATA } from "../../../../services/metadata";
import { useQuery } from "@apollo/client";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.gql.js";
import UISkeleton from "../../../UI/Skeleton";
import UIError from "../../../UI/Error";
import UIFormRelatedURL from "../../../UI/Form/RelatedURL";

const WorkTabsAboutIdentifiersMetadata = ({
  descriptiveMetadata,
  errors,
  isEditing,
  register,
  control,
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
    <div className="columns is-multiline" data-testid="identifiers-metadata">
      {IDENTIFIER_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray
              register={register}
              control={control}
              required
              name={item.name}
              label={item.label}
              errors={errors}
            />
          ) : (
            <UIFormFieldArrayDisplay
              items={descriptiveMetadata[item.name]}
              label={item.label}
            />
          )}
        </div>
      ))}
      {/* RelatedURL entry is the only field which is an array of RelatedUrlEntries
       which is a combination of array of label object and string URL */}
      <div className="column" data-testid="relatedUrl">
        <UIFormField label="Related URL">
          {isEditing ? (
            <UIFormRelatedURL
              codeLists={relatedUrlData.codeList}
              control={control}
              errors={errors}
              label="Related URL"
              name="relatedUrl"
              register={register}
            />
          ) : (
            <div className="field content">
              <ul data-testid="field-array-item-list">
                {descriptiveMetadata.relatedUrl.map((relatedUrlEntry, i) => (
                  <li className="mb-4" key={i}>
                    <p>
                      <strong>URL </strong>
                      {relatedUrlEntry.url}
                    </p>
                    <p>
                      <strong>Label </strong>
                      {relatedUrlEntry.label.label}
                    </p>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutIdentifiersMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  register: PropTypes.func,
};

export default WorkTabsAboutIdentifiersMetadata;
