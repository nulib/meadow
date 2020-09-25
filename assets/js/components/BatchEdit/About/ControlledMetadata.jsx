import React, { useState, useEffect } from "react";
import PropTypes from "prop-types";
import UIFormField from "../../UI/Form/Field";
import UIFormControlledTermArray from "../../UI/Form/ControlledTermArray";
import { CONTROLLED_METADATA } from "../../../services/metadata";
import BatchEditRemove from "../Remove";
import BatchEditModalRemove from "../ModalRemove";
import { useBatchState } from "../../../context/batch-edit-context";
import useCachedCodeLists from "../../../hooks/useCachedCodeLists";
import UICodeListCacheRefresh from "../../UI/CodeListCacheRefresh";

const BatchEditAboutControlledMetadata = ({ ...restProps }) => {
  // This holds all the ElasticSearch Search info
  const batchState = useBatchState();
  const aggregations = batchState.parsedAggregations;

  const [isRemoveModalOpen, setIsRemoveModalOpen] = useState();
  const [currentRemoveField, setCurrentRemoveField] = useState();

  const [codeLists, refreshCodeLists] = useCachedCodeLists();

  useEffect(() => {
    if (!codeLists) {
      refreshCodeLists();
    }
  }, []);

  function getRoleDropDownOptions(scheme) {
    if (scheme === "MARC_RELATOR") {
      return codeLists.MARC_RELATOR;
    }
    if (scheme === "SUBJECT_ROLE") {
      return codeLists.SUBJECT_ROLE;
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

  // Still updating, so return a null
  if (!codeLists) {
    return null;
  }

  return (
    <div data-testid="controlled-metadata" {...restProps}>
      <ul>
        {CONTROLLED_METADATA.map(({ label, name, scheme }) => (
          <li key={name} className="mb-5" data-testid={name}>
            <UIFormField label={label}>
              <UIFormControlledTermArray
                authorities={codeLists.AUTHORITY}
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

      <UICodeListCacheRefresh handleClick={() => refreshCodeLists()} />

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
