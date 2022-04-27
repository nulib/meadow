import React from "react";
import { screen } from "@testing-library/react";
import BatchEditAdministrativeCollection from "./Collection";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "@js/services/testing-helpers";
import {
  getCollectionsMock,
  collectionMock,
} from "@js/components/Collection/collection.gql.mock";

describe("BatchEditAdministrativeCollection component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAdministrativeCollection);
    renderWithRouterApollo(<Wrapped />, { mocks: [getCollectionsMock] });
  });

  it("renders the select element", async () => {
    expect(await screen.findByTestId("collection"));
  });

  it("renders the appropriate option label and value", async () => {
    expect(await screen.findByText(collectionMock.title));
    const options = screen.getAllByTestId("select-option");
    expect(options[0]).toHaveTextContent(collectionMock.title, {
      exact: false,
    });
    expect(options[0].value).toContain(collectionMock.id);
  });
});
