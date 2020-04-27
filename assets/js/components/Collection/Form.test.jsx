import React from "react";
import CollectionForm from "./Form";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
} from "./collection.query.js";
import { renderWithRouterApollo } from "../../services/testing-helpers";

const mocks = [
  {
    request: {
      query: GET_COLLECTIONS,
    },
    result: {
      data: {
        collections: [
          {
            adminEmail: "admin@nu.com",
            description: "asdf asdfasdf",
            featured: true,
            findingAidUrl: "http://something.com",
            id: "01DWHQQYTVKC2THHW8SHRBH2XP",
            keywords: ["any", " work", "foo", "bar"],
            name: "Great collection",
            published: false,
            works: [],
          },
        ],
      },
    },
  },
];

function setupMatchTests() {
  return renderWithRouterApollo(<CollectionForm />, {
    mocks,
    route: "/collection/form",
  });
}

it("displays the collection form", () => {
  const { getByTestId, debug } = setupMatchTests();
  expect(getByTestId("collection-form")).toBeInTheDocument();
});

it("displays all form fields", () => {
  const { queryByTestId } = setupMatchTests();
  expect(queryByTestId("collection-image")).toBeInTheDocument();
  expect(queryByTestId("button-collection-image")).toBeInTheDocument();
  expect(queryByTestId("modal-collection-thumbnail")).toBeInTheDocument();

  expect(queryByTestId("input-collection-name")).toBeInTheDocument();
  expect(queryByTestId("input-collection-type")).toBeInTheDocument();
  expect(queryByTestId("checkbox-featured")).toBeInTheDocument();
  expect(queryByTestId("textarea-description")).toBeInTheDocument();
  expect(queryByTestId("input-finding-aid-url")).toBeInTheDocument();
  expect(queryByTestId("input-admin-email")).toBeInTheDocument();
  expect(queryByTestId("input-keywords")).toBeInTheDocument();
});

it("renders no initial form values when creating a collection", () => {});

it("renders existing collection values in the form when editing a form", () => {});

//TODO: How to test this form with route changes, using useHistory() hook
//TODO: Follow assets/js/screens/Project/Project.test.js for examples
