import React from "react";
import PropTypes from "prop-types";
import UIControlledTermList from "../../../UI/ControlledTerm/List";
import UIFormField from "../../../UI/Form/Field";
import UIFormControlledTermArray from "../../../UI/Form/ControlledTermArray";
import { CONTROLLED_METADATA } from "../../../../services/metadata";
import { useCodeLists } from "@js/context/code-list-context";
import { fieldProvenance } from "@js/components/AIProvenance/Badges";

const WorkTabsAboutControlledMetadata = ({
  descriptiveMetadata,
  isEditing,
  provenance = {},
}) => {
  const codeLists = useCodeLists();

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return codeLists.marcData.codeList;
    }
    if (scheme === "SUBJECT_ROLE") {
      return codeLists.subjectRoleData.codeList;
    }
    return [];
  }

  return (
    <div data-testid="controlled-metadata">
      <ul className="columns is-multiline">
        {!codeLists.isLoading &&
          CONTROLLED_METADATA.map(({ label, name, scheme }) => (
            <li key={name} className="mb-5 column is-half">
              <UIFormField label={label}>
                {isEditing ? (
                  <UIFormControlledTermArray
                    authorities={codeLists.authorityData.codeList}
                    roleDropdownOptions={getRoleDropDownOptions(scheme)}
                    label={label}
                    name={name}
                  />
                ) : (
                  <UIControlledTermList
                    items={descriptiveMetadata[name]}
                    title={label}
                    itemProvenance={
                      fieldProvenance(provenance, name)?.itemProvenance
                    }
                  />
                )}
              </UIFormField>
            </li>
          ))}
      </ul>
    </div>
  );
};

WorkTabsAboutControlledMetadata.propTypes = {
  descriptiveMetadata: PropTypes.object,
  isEditing: PropTypes.bool,
  provenance: PropTypes.object,
};

export default WorkTabsAboutControlledMetadata;
