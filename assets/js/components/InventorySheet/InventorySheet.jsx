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
  const statusQuery = useQuery(
    GET_INVENTORY_SHEET_STATUS,
    {
      variables: { inventorySheetId },
      fetchPolicy: "network-only"
    }
  )

  const progressQuery = useQuery(
    GET_INVENTORY_SHEET_PROGRESS,
    {
      variables: { inventorySheetId },
      fetchPolicy: "network-only"
    }
  );

  if (statusQuery.loading || progressQuery.loading) return <Loading />;
  if (statusQuery.error || progressQuery.error) return <Error error={error} />;
  
  return (
    <>
      <InventorySheetValidations
        inventorySheetId={inventorySheetId}
        initialProgress={progressQuery.data.ingestJobProgress}
        initialStatus={statusQuery.data.ingestJob.state}
        subscribeToInventorySheetProgress={progressQuery.subscribeToMore}
        subscribeToInventorySheetStatus={statusQuery.subscribeToMore}
      />
    </>
  );
};

export default InventorySheet;
