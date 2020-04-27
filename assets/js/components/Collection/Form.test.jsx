import React from "react";
import CollectionForm from "./Form";
import {
  CREATE_COLLECTION,
  UPDATE_COLLECTION,
  GET_COLLECTIONS,
} from "./collection.query.js";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent, waitFor, getAllByLabelText } from "@testing-library/react";
import { Route } from "react-router-dom";

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
            representativeImage: "https://thisIsTest.com",
            featured: true,
            findingAidUrl: "http://something.com",
            id: "01DWHQQYTVKC2THHW8SHRBH2XP",
            keywords: ["any", " work", "foo", "bar"],
            name: "Great collection",
            published: false,
            works: [
              {
                id: "1",
                accessionNumber: "accessNumber1",
                representativeImage: "repImage1url.com",
              },
              {
                id: "2",
                accessionNumber: "accessNumber2",
                representativeImage: "repImage1url.com",
              },
            ],
          },
        ],
      },
    },
  },
];

const mockCollection = {
  adminEmail: "admin@nu.com",
  description: "asdf asdfasdf",
  representativeImage: "https://thisIsTest.com",
  featured: true,
  findingAidUrl: "http://something.com",
  id: "01DWHQQYTVKC2THHW8SHRBH2XP",
  keywords: ["any", " work", "foo", "bar"],
  name: "Great collection",
  published: false,
  works: [
    {
      id: "1",
      accessionNumber: "accessNumber1",
      representativeImage: "repImage1url.com",
    },
    {
      id: "2",
      accessionNumber: "accessNumber2",
      representativeImage: "repImage1url.com",
    },
  ],
};

function setupMatchTests() {
  return renderWithRouterApollo(<CollectionForm />, {
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
  expect(queryByTestId("button-open-image-modal")).toBeInTheDocument();
  expect(queryByTestId("modal-collection-thumbnail")).toBeInTheDocument();

  expect(queryByTestId("input-collection-name")).toBeInTheDocument();
  expect(queryByTestId("input-collection-type")).toBeInTheDocument();
  expect(queryByTestId("checkbox-featured")).toBeInTheDocument();
  expect(queryByTestId("textarea-description")).toBeInTheDocument();
  expect(queryByTestId("input-finding-aid-url")).toBeInTheDocument();
  expect(queryByTestId("input-admin-email")).toBeInTheDocument();
  expect(queryByTestId("input-keywords")).toBeInTheDocument();
});

it("renders no initial form values when creating a collection", async () => {
  const { getByTestId, debug } = renderWithRouterApollo(<CollectionForm />, {
    route: "/collection/form",
  });

  await waitFor(() => {
    expect(getByTestId("input-collection-name")).toHaveValue("");
    const el = getByTestId("collection-image");
    expect(el.getAttribute("src")).toEqual("/images/480x480.png");
    expect(getByTestId("textarea-description")).toHaveValue("");
    expect(getByTestId("input-finding-aid-url")).toHaveValue("");
    expect(getByTestId("input-admin-email")).toHaveValue("");
    expect(getByTestId("input-keywords")).toHaveValue("");
  });
});

it("renders existing collection values in the form when editing a form", async () => {
  const { getByTestId, debug } = renderWithRouterApollo(
    <CollectionForm collection={mockCollection} />,
    {}
  );
  await waitFor(() => {
    expect(getByTestId("input-collection-name")).toHaveValue(
      "Great collection"
    );
    expect(getByTestId("textarea-description")).toHaveValue("asdf asdfasdf");
    expect(getByTestId("input-finding-aid-url")).toHaveValue(
      "http://something.com"
    );
    const el = getByTestId("collection-image");
    expect(el.getAttribute("src")).toEqual(
      "https://thisIsTest.com/square/500,500/0/default.jpg"
    );
    expect(getByTestId("input-admin-email")).toHaveValue("admin@nu.com");
    expect(getByTestId("input-keywords")).toHaveValue("any, work,foo,bar");
  });
});

it("renders collection image modal", async () => {
  const { getByTestId, debug } = renderWithRouterApollo(
    <CollectionForm collection={mockCollection} />,
    {}
  );
  await waitFor(() => {
    fireEvent.click(getByTestId("button-open-image-modal"));
    expect(getByTestId("modal-collection-thumbnail")).toHaveClass("is-active");
  });
});

it("saves collection image", async () => {
  const { getByTestId, getByText, debug } = renderWithRouterApollo(
    <CollectionForm collection={mockCollection} />,
    {}
  );
  await waitFor(() => {
    fireEvent.click(getByTestId("button-open-image-modal"));
    expect(getByTestId("modal-collection-thumbnail")).toHaveClass("is-active");
    expect(getByText("accessNumber1")).toBeInTheDocument();
    fireEvent.click(getByText("accessNumber1"));
    expect(getByTestId("button-set-image")).toBeInTheDocument();
    // fireEvent.click(getByTestId("button-set-image"));
    // expect(location.pathname).toBe("/collection/01DWHQQYTVKC2THHW8SHRBH2XP");
  });
});

//TODO: How to test this form with route changes, using useHistory() hook
//TODO: Follow assets/js/screens/Project/Project.test.js for examples
