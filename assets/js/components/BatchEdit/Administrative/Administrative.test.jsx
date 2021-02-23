import React from "react";
import { waitFor } from "@testing-library/react";
import BatchEditAdministrative from "./Administrative";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "@js/context/batch-edit-context";
import { CodeListProvider } from "@js/context/code-list-context";
import { getCollectionsMock } from "@js/components/Collection/collection.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const items = ["ABC123", "ZYC889"];

describe("BatchEditAdministrative component", () => {
  function setupTest() {
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <CodeListProvider>
          <BatchEditAdministrative items={items} />
        </CodeListProvider>
      </BatchProvider>,
      {
        mocks: [...allCodeListMocks, getCollectionsMock],
      }
    );
  }

  it("renders Batch Edit Administrative form", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-administrative-form")).toBeInTheDocument();
    });
  });

  it("renders the sticky header", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-administrative-sticky-header"));
    });
  });

  it("renders the Batch Collection component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-collection-wrapper"));
    });
  });

  it("renders project metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("project-metadata"));
    });
  });

  it("renders general component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("project-status-metadata"));
    });
  });
});
