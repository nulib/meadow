import React from "react";
import gql from "graphql-tag";
import { useQuery } from "@apollo/react-hooks";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import InventorySheetValidations from "./InventorySheetValidations";

const GET_INVENTORY_SHEET_VALIDATIONS = gql`
  query IngestJobValidations($inventorySheetId: String!) {
    ingestJobValidations(id: $inventorySheetId) {
      validations {
        id
        object {
          content
          errors
          status
        }
      }
    }
  }
`;

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
    <div>
      <InventorySheetValidations
        inventorySheetId={inventorySheetId}
        ingestJobValidations={data.ingestJobValidations}
        subscribeToInventorySheetValidations={subscribeToMore}
      />
    </div>
  );
};

export default InventorySheet;
