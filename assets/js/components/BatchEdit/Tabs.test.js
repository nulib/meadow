import React from "react";
import BatchEditTabs from "./Tabs";
import { waitFor } from "@testing-library/react";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
} from "../../services/testing-helpers";
import {
  codeListLicenseMock,
  codeListRelatedUrlMock,
  codeListRightsStatementMock,
} from "../Work/controlledVocabulary.gql.mock.js";
import { getCollectionsMock } from "../Collection/collection.gql.mock";
import { BatchProvider } from "../../context/batch-edit-context";

const items = ["ABC123", "ZYC889"];

describe("BatchEditTabs component", () => {
  function setupTest() {
    setupCachedCodeListsLocalStorage();
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <BatchEditTabs items={items} />
      </BatchProvider>,
      {
        mocks: [
          codeListLicenseMock,
          codeListRelatedUrlMock,
          codeListRightsStatementMock,
          getCollectionsMock,
        ],
      }
    );
  }

  it("renders the tabs header", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-tabs")).toBeInTheDocument();
      expect(getByTestId("tab-about")).toBeInTheDocument();
      expect(getByTestId("tab-administrative")).toBeInTheDocument();
    });
  });

  it("renders the about tab and content", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("tab-about")).toBeInTheDocument();
      expect(getByTestId("tab-about-content")).toBeInTheDocument();
    });
  });

  it("renders the administrative tab and content", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("tab-administrative")).toBeInTheDocument();
      expect(getByTestId("tab-administrative-content")).toBeInTheDocument();
    });
  });
});
