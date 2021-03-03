import React from "react";
import PropTypes from "prop-types";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import { useCodeLists } from "@js/context/code-list-context";
import UICodedTermItem from "@js/components/UI/CodedTerm/Item";

function WorkAdministrativeTabsGeneral({
  administrativeMetadata,
  isEditing,
  published,
  visibility,
}) {
  const codeLists = useCodeLists();
  const { libraryUnit, preservationLevel, status } = administrativeMetadata;

  return (
    <div>
      <UIFormField label="Library Unit">
        {isEditing ? (
          <UIFormSelect
            isReactHookForm
            name="libraryUnit"
            showHelper={true}
            label="Library Unit"
            options={
              codeLists.libraryUnitData
                ? codeLists.libraryUnitData.codeList
                : []
            }
            defaultValue={libraryUnit ? libraryUnit.id : ""}
          />
        ) : (
          <p>{libraryUnit ? libraryUnit.label : "None selected"}</p>
        )}
      </UIFormField>

      <UIFormField label="Preservation Level">
        {isEditing ? (
          <UIFormSelect
            isReactHookForm
            name="preservationLevel"
            showHelper={true}
            label="Preservation Level"
            options={
              codeLists.preservationLevelData
                ? codeLists.preservationLevelData.codeList
                : []
            }
            defaultValue={preservationLevel ? preservationLevel.id : ""}
          />
        ) : (
          <p>{preservationLevel ? preservationLevel.label : "None selected"}</p>
        )}
      </UIFormField>

      <UIFormField label="Status">
        {isEditing ? (
          <UIFormSelect
            data-testid="status"
            isReactHookForm
            name="status"
            label="Status"
            showHelper={true}
            options={codeLists.statusData ? codeLists.statusData.codeList : []}
            defaultValue={status ? status.id : ""}
          />
        ) : (
          <p>{status ? status.label : "None selected"}</p>
        )}
      </UIFormField>
      <UIFormField label="Visibility">
        {isEditing ? (
          <UIFormSelect
            data-testid="visibility"
            isReactHookForm
            name="visibility"
            label="Visibility"
            showHelper={true}
            options={
              codeLists.visibilityData ? codeLists.visibilityData.codeList : []
            }
            defaultValue={visibility ? visibility.id : ""}
          />
        ) : (
          <UICodedTermItem item={visibility} />
        )}
      </UIFormField>
    </div>
  );
}

WorkAdministrativeTabsGeneral.propTypes = {
  administrativeMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
  published: PropTypes.bool,
  visibility: PropTypes.object,
};

export default WorkAdministrativeTabsGeneral;
