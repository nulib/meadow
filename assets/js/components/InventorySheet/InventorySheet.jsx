import React, { useState } from "react";
import gql from "graphql-tag";
import { Query } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";
import InventorySheetValidations from "./InventorySheetValidations"

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

  return (
    <div>
      <h1>Inventory Sheet: {inventorySheetId}</h1>
      <Query query={GET_INVENTORY_SHEET_VALIDATIONS}
        variables={{ inventorySheetId: inventorySheetId }}
        fetchPolicy="network-only">
        {({ data, loading, error, subscribeToMore }) => {
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
        }}
      </Query>
    </div>
  );
}

export default InventorySheet;