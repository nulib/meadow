import React from "react";
import BatchEditTabs from "./Tabs";
import { waitFor, screen } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { allCodeListMocks } from "../Work/controlledVocabulary.gql.mock.js";
import { getCollectionsMock } from "../Collection/collection.gql.mock";
import { BatchProvider } from "../../context/batch-edit-context";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

const items = ["ABC123", "ZYC889"];

describe("BatchEditTabs component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <BatchProvider value={null}>
          <BatchEditTabs items={items} />
        </BatchProvider>
      </AuthProvider>,
      {
        mocks: [...allCodeListMocks, getCollectionsMock, getCurrentUserMock],
      }
    );
  });

  it("renders the tabs header", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("batch-edit-tabs"));
      expect(screen.getByTestId("tab-about"));
      expect(screen.getByTestId("tab-administrative"));
    });
  });

  it("renders the about tab and content", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("tab-about"));
      expect(screen.getByTestId("tab-about-content"));
    });
  });

  it("renders the administrative tab and content", async () => {
    await waitFor(() => {
      expect(screen.getByTestId("tab-administrative"));
      expect(screen.getByTestId("tab-administrative-content"));
    });
  });
});
