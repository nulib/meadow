import React from "react";
import { screen } from "@testing-library/react";
import BatchEditAdministrative from "./Administrative";
import {
  withReactHookForm,
  renderWithRouterApollo,
} from "@js/services/testing-helpers";
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

//const items = ["ABC123", "ZYC889"];

describe("BatchEditAdministrative component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(BatchEditAdministrative, {
      batchPublish: {
        publish: false,
        unpublish: false,
      },
      setBatchPublish: jest.fn(),
    });

    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <CodeListProvider>
          <Wrapped />
        </CodeListProvider>
      </BatchProvider>,
      {
        mocks: [...allCodeListMocks, getCollectionsMock],
      }
    );
  });

  it("renders Batch Edit Administrative component", async () => {
    expect(await screen.findByTestId("batch-edit-administrative-tab-wrapper"));
  });

  it("renders the Batch Collection component", async () => {
    expect(await screen.findByTestId("batch-collection-wrapper"));
  });

  it("renders project metadata component", async () => {
    expect(await screen.findByTestId("project-metadata"));
  });

  it("renders general component", async () => {
    expect(await screen.findByTestId("project-status-metadata"));
  });
});
