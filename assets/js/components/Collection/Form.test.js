import React from "react";
import CollectionForm from "./Form";
import {
  renderWithRouterApollo,
  withReactHookForm,
} from "../../services/testing-helpers";
import { screen } from "@testing-library/react";
import { collectionMock } from "./collection.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { CodeListProvider } from "@js/context/code-list-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("Collection Form component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(CollectionForm);
    renderWithRouterApollo(
      <CodeListProvider>
        <Wrapped />
      </CodeListProvider>,
      {
        route: "/collection/form",
        mocks: [...allCodeListMocks],
      }
    );
  });

  it("displays the collection form", async () => {
    expect(await screen.findByTestId("collection-form"));
  });

  it("displays all form fields", async () => {
    expect(await screen.findByTestId("input-collection-title"));
    expect(await screen.findByTestId("checkbox-featured"));
    expect(await screen.findByTestId("textarea-description"));
    expect(await screen.findByTestId("input-finding-aid-url"));
    expect(await screen.findByTestId("input-admin-email"));
    expect(await screen.findByTestId("input-keywords"));
    expect(await screen.findByTestId("visibility"));
    expect(await screen.findByTestId("checkbox-published"));
  });

  it("renders no initial form values when creating a collection", async () => {
    expect(await screen.findByTestId("input-collection-title")).toHaveValue("");
    expect(await screen.findByTestId("textarea-description")).toHaveValue("");
    expect(await screen.findByTestId("input-finding-aid-url")).toHaveValue("");
    expect(await screen.findByTestId("input-admin-email")).toHaveValue("");
    expect(await screen.findByTestId("input-keywords")).toHaveValue("");
  });
});

it("renders existing collection values in the form when editing a form", async () => {
  const Wrapped = withReactHookForm(CollectionForm, {
    collection: collectionMock,
  });
  renderWithRouterApollo(
    <CodeListProvider>
      <Wrapped />
    </CodeListProvider>,
    {
      route: "/collection/form",
      mocks: [...allCodeListMocks],
    }
  );

  expect(await screen.findByTestId("input-collection-title")).toHaveValue(
    "Great collection"
  );
  expect(await screen.findByTestId("textarea-description")).toHaveValue(
    "Collection description lorem ipsum"
  );
  expect(await screen.findByTestId("input-finding-aid-url")).toHaveValue(
    "https://northwestern.edu"
  );

  expect(await screen.findByTestId("input-admin-email")).toHaveValue(
    "admin@nu.com"
  );
  expect(await screen.findByTestId("input-keywords")).toHaveValue(
    "yo,foo,bar,work,hey"
  );
});

//TODO: How to test this form with route changes, using useHistory() hook
//TODO: Follow assets/js/screens/Project/Project.test.js for examples
