import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { useMutation } from "@apollo/react-hooks";
import InventorySheetErrorsState from "./ErrorsState";
import InventorySheetUnapprovedState from "./UnapprovedState";
import {
  SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS,
  START_VALIDATION
} from "./inventorySheet.query";

function InventorySheetValidations({
  inventorySheetId,
  ingestJobRows,
  subscribeToInventorySheetValidations
}) {
  const [hasErrors, setHasErrors] = useState(true);
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);

  useEffect(() => {
    setHasErrors(jobHasErrors({ingestJobRows: ingestJobRows}));
    startValidation({ variables: { id: inventorySheetId } });
    subscribeToInventorySheetValidations({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS,
      variables: { ingestJobId: inventorySheetId },
      updateQuery: handleValidationUpdate
    });
  }, []);

  const jobHasErrors = ({ingestJobRows}) => {
    return ingestJobRows.filter(row => row.state === "FAIL").length > 0;
  };

  const handleValidationUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const newValidation = subscriptionData.data.ingestJobRowUpdate;
    const index = prev.ingestJobRows.findIndex(
      ({ id }) => id === newValidation.id
    );
    let updatedValidations;

    if (index === -1) {
      updatedValidations = [
        newValidation,
        ...prev.ingestJobRows
      ];
    } else {
      updatedValidations = prev.ingestJobRows;
      updatedValidations[index] = newValidation;
    }

    const ingestJobRows = {
      ...prev.ingestJobRows,
      validations: updatedValidations
    };

    setHasErrors(jobHasErrors(ingestJobRows));

    return {
      ingestJobRows
    };
  };

  if (hasErrors) {
    return (
      <div>
      <InventorySheetErrorsState
        validations={ingestJobRows}
      />
      </div>
    );
  } else {
    return (
      <div>
      <InventorySheetUnapprovedState
        validations={ingestJobRows}
      />
      </div>
    );
  }

  return null;
}

InventorySheetValidations.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  ingestJobRows: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default InventorySheetValidations;
