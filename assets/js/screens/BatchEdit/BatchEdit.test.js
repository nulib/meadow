import React from "react";
import { waitFor, screen } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import ScreensBatchEdit from "./BatchEdit";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { getCollectionsMock } from "../../components/Collection/collection.gql.mock";
import { BatchProvider } from "../../context/batch-edit-context";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

jest.mock("../../services/elasticsearch");

describe("BatchEdit component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
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
        </BatchProvider>
      </AuthProvider>,
      {
        mocks: [...allCodeListMocks, getCollectionsMock, getCurrentUserMock],
        // NOTE: We're not using this in the component anymore, but keeping it in for a pattern to
        // reference in the future.
        state: { resultStats: { numberOfResults: 5 } },
      }
    );
  });

  it("renders without crashing", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("batch-edit-screen"));
    });
  });

  it("renders breadcrumbs", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("breadcrumbs"));
    });
  });

  it("renders screen title and number of records editing", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("batch-edit-title"));
    });
  });

  it("renders the item preview window", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("preview-wrapper"));
    });
  });

  it("renders Tabs section", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("tabs-wrapper"));
    });
  });
});
