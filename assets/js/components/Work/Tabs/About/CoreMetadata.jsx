import React from "react";
import PropTypes from "prop-types";
import UITagNotYetSupported from "../../../UI/TagNotYetSupported";
import UIInput from "../../../UI/Form/Input";
import UIFormTextarea from "../../../UI/Form/Textarea";
import UIFormField from "../../../UI/Form/Field";
import UIFormSelect from "../../../UI/Form/Select";
import UIFormFieldArray from "../../../UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "../../../UI/Form/FieldArrayDisplay";
import UICodedTermItem from "../../../UI/CodedTerm/Item";
import { useCodeLists } from "@js/context/code-list-context";

const WorkTabsAboutCoreMetadata = ({
  descriptiveMetadata,
  isEditing,
  published,
}) => {
  const codeLists = useCodeLists();

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

      <div className="column is-half">
        <UIFormField label="Date Created" notLive>
          {isEditing ? (
            <UIInput
              name="dateCreated"
              label="Date Created"
              data-testid="date-created"
              defaultValue={descriptiveMetadata.dateCreated}
            />
          ) : (
            <>
              <UITagNotYetSupported label="Display not yet supported" />
              <UITagNotYetSupported label="Update not yet supported" />
            </>
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
