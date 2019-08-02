import React, { useState } from "react";
import gql from "graphql-tag";
import { Subscription } from "react-apollo";
import Error from "../UI/Error";
import Loading from "../UI/Loading";

import { print } from "graphql/language/printer";

const SUB = gql`
  subscription IngestJobChange($ingestJobId: String!) {
    ingestJobChange(ingestJobId: $ingestJobId) {
      name
      state
      updatedAt
    }
  }
`;

const TestSub = ({ match }) => {
  const { inventorySheetId } = match.params;

  console.log(print(SUB));

  return (
    <div>
      <h1>Ingest Job Id: {inventorySheetId}</h1>
      <Subscription
        subscription={SUB}
        variables={{ ingestJobId: inventorySheetId }}
      >
        {({ data, loading, error }) => {
          if (loading) return <Loading />;
          if (error) return <Error error={error} />;
          console.log(data);
          return (
            <div>
              <h3>State: {data.ingestJobChange.state}</h3>
            </div>
          );
        }}
      </Subscription>
    </div>
  );
};

export default TestSub;
