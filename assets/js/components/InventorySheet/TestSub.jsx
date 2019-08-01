import React, { useState } from "react";
import gql from "graphql-tag";
import { Subscription } from "react-apollo";

import { print } from 'graphql/language/printer'

const SUB = gql`
  subscription IngestJobChange { ingestJobChange(ingestJobId:"01DH1XZ3YDZWTAD24B5JTSYD9M") { name updatedAt }}
`;



export default class TestSub extends React.PureComponent {
  render() {
    console.log("hiiiii")
    console.log(print(SUB))
    return (
      <div>
        <h1>hi</h1>
        
        <Subscription subscription={SUB}>
          {data => {
            console.log(data);
            return <h1>Hey {data}</h1>;
          }}
        </Subscription>

      </div>
    );
  }
}