import PropTypes from "prop-types";
import React from "react";
import UIFormField from "@js/components/UI/Form/Field";
import UIFormSelect from "@js/components/UI/Form/Select";
import { useCodeLists } from "@js/context/code-list-context";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";
import usePassedInSearchTerm from "@js/hooks/usePassedInSearchTerm";

function WorkAdministrativeTabsGeneral({
  administrativeMetadata,
  isEditing,
  visibility,
}) {
  const codeLists = useCodeLists();
  const { libraryUnit, preservationLevel, status } = administrativeMetadata;
  const { handleFacetLinkClick } = useFacetLinkClick();
  const { handlePassedInSearchTerm } = usePassedInSearchTerm();

  return (
    <div>
      <UIFormField label="Library Unit" data-testid="library-unit-wrapper">
        {isEditing ? (
          <UIFormSelect
            data-testid="library-unit"
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
        ) : libraryUnit ? (
          <a
            data-testid="library-unit-link"
            className="break-word"
            onClick={() =>
              handleFacetLinkClick("LibraryUnit", libraryUnit.label)
            }
          >
            {libraryUnit.label}
          </a>
        ) : (
          <p>None selected</p>
        )}
      </UIFormField>

      <UIFormField
        label="Preservation Level"
        data-testid="preservation-level-wrapper"
      >
        {isEditing ? (
          <UIFormSelect
            data-testid="preservation-level"
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
        ) : preservationLevel ? (
          <a
            data-testid="preservation-level-link"
            className="break-word"
            onClick={() =>
              handlePassedInSearchTerm(
                "administrativeMetadata.preservationLevel.label",
                preservationLevel.label
              )
            }
          >
            {preservationLevel.label}
          </a>
        ) : (
          <p>None selected</p>
        )}
      </UIFormField>

      <UIFormField label="Status" data-testid="status-wrapper">
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
        ) : status ? (
          <a
            data-testid="status-link"
            className="break-word"
            onClick={() =>
              handlePassedInSearchTerm(
                "status",
                status.label
              )
            }
          >
            {status.label}
          </a>
        ) : (
          <p>None selected</p>
        )}
      </UIFormField>
      <UIFormField label="Visibility" data-testid="visibility-wrapper">
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
        ) : visibility ? (
          <a
            data-testid="visibility-link"
            className="break-word"
            onClick={() => handleFacetLinkClick("Visibility", visibility.label)}
          >
            {visibility.label}
          </a>
        ) : (
          <p>None selected</p>
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
