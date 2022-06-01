import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";
import UIFormNote from "@js/components/UI/Form/Note";
import { useCodeLists } from "@js/context/code-list-context";

const WorkTabsAboutUncontrolledMetadata = ({
  descriptiveMetadata,
  isEditing,
}) => {
  const codeLists = useCodeLists();

  return (
    <div className="columns is-multiline" data-testid="uncontrolled-metadata">
      {UNCONTROLLED_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray 
              required 
              name={item.name} 
              label={item.label} 
              isTextarea={item.inputEl && item.inputEl === 'textarea'} />
          ) : (
            <UIFormFieldArrayDisplay
              values={descriptiveMetadata[item.name]}
              label={item.label}
            />
          )}
        </div>
      ))}
      {/* Note entry is the only field which is an array of NoteEntries
       which is a combination of array of noteType object and string note */}
      <div className="column" data-testid="notes">
        <UIFormField label="Notes">
          {isEditing ? (
            <UIFormNote
              codeLists={
                codeLists.notesData ? codeLists.notesData.codeList : []
              }
              label="Notes"
              name="notes"
            />
          ) : (
            <div className="field content">
              <ul data-testid="field-array-item-list">
                {descriptiveMetadata.notes.map((noteEntry, i) => (
                  <li className="mb-4" key={i}>
                    {noteEntry.type.label} - {noteEntry.note}
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

WorkTabsAboutUncontrolledMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
};

export default WorkTabsAboutUncontrolledMetadata;
