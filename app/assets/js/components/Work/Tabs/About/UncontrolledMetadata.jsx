import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormFieldArray from "@js/components/UI/Form/FieldArray";
import UIFormFieldArrayDisplay from "@js/components/UI/Form/FieldArrayDisplay";
import { UNCONTROLLED_METADATA } from "@js/services/metadata";
import UIFormNote from "@js/components/UI/Form/Note";
import { useCodeLists } from "@js/context/code-list-context";
import {
  OriginBadge,
  fieldProvenance,
  provenanceItemId,
} from "@js/components/AIProvenance/Badges";
import { ItemAttestation } from "@js/components/AIProvenance/ItemAttestationControl";

const WorkTabsAboutUncontrolledMetadata = ({
  descriptiveMetadata,
  isEditing,
  provenance = {},
  workId,
}) => {
  const codeLists = useCodeLists();

  // Per-note AI origin, keyed by note text (the backend's item identifier), so
  // each note is badged individually rather than with one field-level badge.
  const notesOriginById = (
    fieldProvenance(provenance, "notes")?.itemProvenance || []
  ).reduce((acc, entry) => {
    if (entry?.id) acc[entry.id] = entry.origin;
    return acc;
  }, {});

  return (
    <div className="columns is-multiline" data-testid="uncontrolled-metadata">
      {UNCONTROLLED_METADATA.map((item) => (
        <div className="column is-half" key={item.name} data-testid={item.name}>
          {isEditing ? (
            <UIFormFieldArray
              required
              name={item.name}
              label={item.label}
              isTextarea={item.inputEl && item.inputEl === "textarea"}
            />
          ) : (
            <UIFormFieldArrayDisplay
              values={descriptiveMetadata[item.name]}
              label={item.label}
              provenance={fieldProvenance(provenance, item.name)}
              workId={workId}
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
                {descriptiveMetadata.notes.map((noteEntry, i) => {
                  const origin = notesOriginById[provenanceItemId(noteEntry)];
                  return (
                    <li className="mb-4" key={i}>
                      {noteEntry.type.label} - {noteEntry.note}
                      {origin && (
                        <span className="ml-2">
                          <OriginBadge origin={origin} />
                        </span>
                      )}
                      {origin && (
                        <ItemAttestation
                          origin={origin}
                          workId={workId}
                          fieldPath={
                            fieldProvenance(provenance, "notes")?.fieldPath
                          }
                          itemId={provenanceItemId(noteEntry)}
                        />
                      )}
                    </li>
                  );
                })}
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
  provenance: PropTypes.object,
  workId: PropTypes.string,
};

export default WorkTabsAboutUncontrolledMetadata;
