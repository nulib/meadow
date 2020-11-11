import React from "react";
import PropTypes from "prop-types";
import UIInput from "../../../UI/Form/Input";
import UIFormField from "../../../UI/Form/Field";
import UIFormSelect from "../../../UI/Form/Select";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { useCodeLists } from "@js/context/code-list-context";
import { isEDTFValid } from "../../../../services/helpers";

const WorkTabsAboutCoreMetadata = ({
  descriptiveMetadata,
  isEditing,
  published,
}) => {
  const codeLists = useCodeLists();
  const EDTFValidateFn = (value) => {
    return isEDTFValid(value) || <span>Please enter raw EDTF date. </span>;
  };

  return (
    <div className="columns is-multiline" data-testid="core-metadata">
      <div className="column is-two-thirds">
        <UIFormField label="Title" required={published}>
          {isEditing ? (
            <UIInput
              isReactHookForm
              name="title"
              label="Title"
              data-testid="title"
              required={published}
              defaultValue={descriptiveMetadata.title}
            />
          ) : (
            <p>{descriptiveMetadata.title || "No value"}</p>
          )}
        </UIFormField>
      </div>

      <div className="column is-half">
        {/* Description */}
        {isEditing ? (
          <UIFormFieldArray
            name="description"
            data-testid="description"
            label="Description"
            isTextarea={true}
          />
        ) : (
          <UIFormFieldArrayDisplay
            items={descriptiveMetadata.description}
            label="Description"
          />
        )}
      </div>

      <div className="column is-half">
        {isEditing ? (
          <UIFormFieldArray
            name="alternateTitle"
            data-testid="alternate-title"
            label="Alternate Title"
          />
        ) : (
          <UIFormFieldArrayDisplay
            items={descriptiveMetadata.alternateTitle}
            label="Alternate Title"
          />
        )}
      </div>
      <div className="column is-half">
        {isEditing ? (
          <UIFormFieldArray
            label="Date Created"
            name="dateCreated"
            data-testid="date-created"
            validateFn={EDTFValidateFn}
          />
        ) : (
          <UIFormField label="Date Created">
            <div className="field content">
              <ul className="field-array-item-list">
                {descriptiveMetadata.dateCreated &&
                  descriptiveMetadata.dateCreated.length > 0 &&
                  descriptiveMetadata.dateCreated.map((datefield, i) => (
                    <li key={i}>
                      {datefield ? datefield.humanized : "No Date specified"}
                    </li>
                  ))}
              </ul>
            </div>
          </UIFormField>
        )}
      </div>
      <div className="column is-half">
        {/* Rights Statement */}
        <UIFormField label="Rights Statement">
          {isEditing ? (
            <UIFormSelect
              isReactHookForm
              name="rightsStatement"
              label="Rights Statement"
              showHelper={true}
              data-testid="rights-statement"
              options={
                codeLists.rightsStatementData
                  ? codeLists.rightsStatementData.codeList
                  : []
              }
              defaultValue={
                descriptiveMetadata.rightsStatement
                  ? descriptiveMetadata.rightsStatement.id
                  : ""
              }
            />
          ) : (
            <UICodedTermItem item={descriptiveMetadata.rightsStatement} />
          )}
        </UIFormField>
      </div>
    </div>
  );
};

WorkTabsAboutCoreMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
  published: PropTypes.bool,
};

export default WorkTabsAboutCoreMetadata;
