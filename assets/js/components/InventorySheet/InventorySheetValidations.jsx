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
  ingestJobValidations,
  subscribeToInventorySheetValidations
}) {
  const [hasErrors, setHasErrors] = useState(true);
  const [startValidation, { validationData }] = useMutation(START_VALIDATION);

  useEffect(() => {
    startValidation({ variables: { id: inventorySheetId } });
    subscribeToInventorySheetValidations({
      document: SUBSCRIBE_TO_INVENTORY_SHEET_VALIDATIONS,
      variables: { ingestJobId: inventorySheetId },
      updateQuery: handleValidationUpdate
    });
  }, []);

  const jobHasErrors = ({ validations }) => {
    return validations.filter(row => row.object.status === "fail").length > 0;
  };

  const handleValidationUpdate = (prev, { subscriptionData }) => {
    if (!subscriptionData.data) return prev;

    const newValidation = subscriptionData.data.ingestJobValidationUpdate;
    const index = prev.ingestJobValidations.validations.findIndex(
      ({ id }) => id === newValidation.id
    );
    let updatedValidations;

    if (index === -1) {
      updatedValidations = [
        newValidation,
        ...prev.ingestJobValidations.validations
      ];
    } else {
      updatedValidations = prev.ingestJobValidations.validations;
      updatedValidations[index] = newValidation;
    }

    const ingestJobValidations = {
      ...prev.ingestJobValidations,
      validations: updatedValidations
    };

    setHasErrors(jobHasErrors(ingestJobValidations));

    return {
      ingestJobValidations
    };
  };

  if (hasErrors) {
    return (
      <InventorySheetErrorsState
        validations={ingestJobValidations.validations}
      />
    );
  } else {
    return (
      <InventorySheetUnapprovedState
        validations={ingestJobValidations.validations}
      />
    );
  }

  return null;
}

InventorySheetValidations.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  ingestJobValidations: PropTypes.object.isRequired
};

export default InventorySheetValidations;
