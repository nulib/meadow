import React from "react";
import CollectionForm from "./Form";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS
} from "./collection.query.js";
import { renderWithRouterApollo, wrapWithToast } from "../../testing-helpers";
import "@testing-library/jest-dom/extend-expect";
import { Route } from "react-router-dom";
import { waitForElement, render } from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GET_COLLECTIONS
    },
    result: {
      data: {
        collections: [
          {
            description: "asdf asdfasdf",
            id: "01DWHQQYTVKC2THHW8SHRBH2XP",
            keywords: ["any", " work"],
            name: "Great collection"
          }
        ]
      }
    }
  }
];

function setupMatchTests() {
  return renderWithRouterApollo(wrapWithToast(<CollectionForm />), {
    mocks,
    route: "/collection/form"
  });
}

it("displays the collection form", () => {
  const { getByTestId, debug } = setupMatchTests();
  expect(getByTestId("collection-form")).toBeInTheDocument();
});

//TODO: Figure out how to mock fragments when pulling in gql queries
//TODO: How to test this form with route changes, using useHistory() hook
//TODO: Follow assets/js/screens/Project/Project.test.js for examples
