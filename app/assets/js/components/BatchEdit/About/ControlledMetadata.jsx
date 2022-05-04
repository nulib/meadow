import React, { useState } from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormControlledTermArray from "../../UI/Form/ControlledTermArray";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import BatchEditRemove from "../Remove";
import BatchEditModalRemove from "../ModalRemove";
import { useBatchState } from "../../../context/batch-edit-context";
import { useCodeLists } from "@js/context/code-list-context";

const BatchEditAboutControlledMetadata = ({ ...restProps }) => {
  // This holds all the ElasticSearch Search info
  const batchState = useBatchState();
  const aggregations = batchState.parsedAggregations;

  const [isRemoveModalOpen, setIsRemoveModalOpen] = useState();
  const [currentRemoveField, setCurrentRemoveField] = useState();

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

  function handleRemoveButtonClick(fieldObj) {
    setCurrentRemoveField(fieldObj);
    setIsRemoveModalOpen(true);
  }

  function handleCloseRemoveModalClick() {
    setIsRemoveModalOpen(false);
  }

  return (
    <div data-testid="controlled-metadata" {...restProps}>
      <ul className="columns is-multiline">
        {!codeLists.isLoading &&
          CONTROLLED_METADATA.map(({ label, name, scheme }) => (
            <li key={name} className="column is-half mb-5" data-testid={name}>
              <UIFormField label={label}>
                <UIFormControlledTermArray
                  authorities={codeLists.authorityData.codeList}
                  roleDropdownOptions={getRoleDropDownOptions(scheme)}
                  label={label}
                  name={name}
                />
              </UIFormField>
              <BatchEditRemove
                handleRemoveClick={handleRemoveButtonClick}
                label={label}
                name={name}
                removeItems={
                  (batchState.removeItems && batchState.removeItems[name]) || []
                }
              />
            </li>
          ))}
      </ul>

      <BatchEditModalRemove
        closeModal={handleCloseRemoveModalClick}
        currentRemoveField={currentRemoveField}
        items={
          aggregations && currentRemoveField
            ? aggregations[currentRemoveField.name]
            : []
        }
        isRemoveModalOpen={isRemoveModalOpen}
      />
    </div>
  );
};

BatchEditAboutControlledMetadata.propTypes = {
  restProps: PropTypes.object,
};

export default BatchEditAboutControlledMetadata;
