import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import InventorySheetValidations from "./InventorySheetValidations";
import {
  GET_INVENTORY_SHEET_STATUS,
  GET_INVENTORY_SHEET_PROGRESS
} from "./inventorySheet.query";

const InventorySheet = ({ inventorySheetId }) => {
  const {
    data: statusData,
    loading: statusLoading,
    error: statusError,
    subscribeToMore: statusSubscribeToMore
  } = useQuery(GET_INVENTORY_SHEET_STATUS, {
    variables: { inventorySheetId },
    fetchPolicy: "network-only"
  });

  const {
    data: progressData,
    loading: progressLoading,
    error: progressError,
    subscribeToMore: progressSubscribeToMore
  } = useQuery(GET_INVENTORY_SHEET_PROGRESS, {
    variables: { inventorySheetId },
    fetchPolicy: "network-only"
  });

  if (statusLoading || progressLoading) return <Loading />;
  if (statusError || progressError)
    return <Error error={statusError || progressError} />;

  return (
    <>
      <InventorySheetValidations
        inventorySheetId={inventorySheetId}
        initialProgress={progressData.ingestJobProgress}
        initialStatus={statusData.ingestJob.state}
        subscribeToInventorySheetProgress={progressSubscribeToMore}
        subscribeToInventorySheetStatus={statusSubscribeToMore}
      />
    </>
  );
};

export default InventorySheet;
