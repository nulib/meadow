import React from "react";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
} from "../../services/testing-helpers";
import ScreensBatchEdit from "./BatchEdit";
import {
  codeListLicenseMock,
  codeListRelatedUrlMock,
  codeListRightsStatementMock,
} from "../../components/Work/controlledVocabulary.gql.mock";
import { getCollectionsMock } from "../../components/Collection/collection.gql.mock";
import { BatchProvider } from "../../context/batch-edit-context";

jest.mock("../../services/elasticsearch");

describe("BatchEdit component", () => {
  function setupComponent() {
    setupCachedCodeListsLocalStorage();
    return renderWithRouterApollo(
      <BatchProvider
        initialState={{
          filteredQuery: { foo: "bar" },
          resultStats: {
            numberOfResults: 17,
            numberOfPages: 2,
            time: 23,
            hidden: 0,
            promoted: 0,
            currentPage: 0,
            displayedResults: 10,
          },
        }}
      >
        <ScreensBatchEdit />
      </BatchProvider>,
      {
        mocks: [
          codeListLicenseMock,
          codeListRelatedUrlMock,
          codeListRightsStatementMock,
          getCollectionsMock,
        ],
        // NOTE: We're not using this in the component anymore, but keeping it in for a pattern to
        // reference in the future.
        state: { resultStats: { numberOfResults: 5 } },
      }
    );
  }

  it("renders without crashing", async () => {
    const { getByTestId } = setupComponent();
    await waitFor(() => {
      expect(getByTestId("batch-edit-screen")).toBeInTheDocument();
    });
  });

  it("renders breadcrumbs", async () => {
    const { getByTestId } = setupComponent();

    await waitFor(() => {
      expect(getByTestId("breadcrumbs")).toBeInTheDocument();
    });
  });

  it("renders screen title and number of records editing", async () => {
    const { getByTestId } = setupComponent();

    await waitFor(() => {
      expect(getByTestId("batch-edit-title")).toBeInTheDocument();
    });
  });

  it("renders the item preview window", async () => {
    const { getByTestId } = setupComponent();

    await waitFor(() => {
      expect(getByTestId("preview-wrapper")).toBeInTheDocument();
    });
  });

  it("renders Tabs section", async () => {
    const { getByTestId } = setupComponent();

    await waitFor(() => {
      expect(getByTestId("tabs-wrapper")).toBeInTheDocument();
    });
  });
});
