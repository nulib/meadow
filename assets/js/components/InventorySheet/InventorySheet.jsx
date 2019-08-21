import React from "react";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import InventorySheetValidations from "./InventorySheetValidations";
import { GET_INVENTORY_SHEET_VALIDATIONS } from "./inventorySheet.query";

const InventorySheet = ({ inventorySheetId }) => {
  const { loading, error, data, subscribeToMore } = useQuery(
    GET_INVENTORY_SHEET_VALIDATIONS,
    {
      variables: { inventorySheetId },
      fetchPolicy: "network-only"
    }
  );

  if (loading) return <Loading />;
  if (error) return <Error error={error} />;

  return (
    <>
      <InventorySheetValidations
        inventorySheetId={inventorySheetId}
        ingestJobRows={data.ingestJobRows}
        subscribeToInventorySheetValidations={subscribeToMore}
      />
    </>
  );
};

export default InventorySheet;
