import React, { useEffect, useState } from "react";
import PropTypes from "prop-types";
import { useMutation, useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import InventorySheetErrorsState from "./ErrorsState";
import InventorySheetUnapprovedState from "./UnapprovedState";
import {
  GET_INVENTORY_SHEET_ERRORS,
  GET_INVENTORY_SHEET_VALIDATIONS
} from "./inventorySheet.query";

function InventorySheetReport({
  inventorySheetId,
  progress,
  jobState
}) {
  const jobHasErrors = () => {
    console.log(jobState);
    if (jobState.find(({state}) => state == "FAIL")) {
      return true;
    }
    const fails = progress.states.find(({state}) => state == "FAIL");
    return (fails && fails.count > 0);
  };

  const { loading, error, data }= useQuery(
    jobHasErrors() ? GET_INVENTORY_SHEET_ERRORS : GET_INVENTORY_SHEET_VALIDATIONS,
    {
      variables: { inventorySheetId },
      fetchPolicy: "network-only"
    }
  );

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  const ingestJobRows = data.ingestJobRows;

  if (jobHasErrors()) {
    return (
      <InventorySheetErrorsState
        validations={ingestJobRows}
      />
    )
  } else {
    return (
      <>
        <InventorySheetUnapprovedState
          validations={ingestJobRows}
        />
      </>
    );  
  }

}

InventorySheetReport.propTypes = {
  inventorySheetId: PropTypes.string.isRequired,
  progress: PropTypes.object.isRequired,
  jobState: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default InventorySheetReport;
