import React from "react";
import PropTypes from "prop-types";
import UIFormField from "../../../UI/Form/Field";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { CODE_LIST_QUERY } from "../../controlledVocabulary.query.js";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { useQuery } from "@apollo/react-hooks";
import UIError from "../../../UI/Error";

const WorkTabsAboutDescriptiveMetadata = ({
  control,
  descriptiveMetadata,
  errors,
  isEditing,
  genericDescriptiveMetadata,
  register,
  showDescriptiveMetadata,
}) => {
  const {
    data: marcData,
    loading: marcLoading,
    errors: marcErrors,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "MARC_RELATOR" } });

  const {
    data: authorityData,
    loading: authorityLoading,
    errors: authorityErrors,
  } = useQuery(CODE_LIST_QUERY, { variables: { scheme: "AUTHORITY" } });

  if (marcLoading || authorityLoading) return null;
  if (marcErrors || authorityErrors)
    return <UIError error={marcErrors || authorityErrors} />;

  const codeLists = {
    authorities: authorityData.codeList,
    marcRelators: marcData.codeList,
  };

  return showDescriptiveMetadata ? (
    <div>
      <h3
        className="subtitle is-size-5 is-marginless"
        style={{ paddingBottom: "1rem" }}
      >
        Generic Terms
      </h3>
      <div className="columns is-multiline">
        {genericDescriptiveMetadata.map((item) => (
          <div key={item.name} className="column is-half">
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
      </div>
      <hr />
      <h3 className="subtitle is-size-5 ">Controlled Terms</h3>
      <div className="columns is-multiline">
        <div className="column is-half">
          <UIFormField label="Contributors" mocked notLive>
            {isEditing ? (
              <UIFormControlledTermArray
                codeLists={codeLists}
                control={control}
                errors={errors}
                label="Contributors"
                name="contributor"
                register={register}
              />
            ) : (
              <UIControlledTermList items={descriptiveMetadata.contributor} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Creators" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.creator} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Genre" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.genre} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Language" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.language} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="License" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UICodedTermItem item={descriptiveMetadata.license} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Location" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.location} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Style Period" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.stylePeriod} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Subject" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.subject} />
            )}
          </UIFormField>
        </div>
        <div className="column is-half">
          <UIFormField label="Technique" mocked notLive>
            {isEditing ? (
              <p>Form elements go here</p>
            ) : (
              <UIControlledTermList items={descriptiveMetadata.technique} />
            )}
          </UIFormField>
        </div>
      </div>
    </div>
  ) : null;
};

WorkTabsAboutDescriptiveMetadata.propTypes = {
  control: PropTypes.object.isRequired,
  descriptiveMetadata: PropTypes.object.isRequired,
  errors: PropTypes.object,
  isEditing: PropTypes.bool,
  genericDescriptiveMetadata: PropTypes.array.isRequired,
  register: PropTypes.func.isRequired,
  showDescriptiveMetadata: PropTypes.bool,
};

export default WorkTabsAboutDescriptiveMetadata;
