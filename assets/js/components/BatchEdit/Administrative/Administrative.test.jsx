import React from "react";
import { waitFor } from "@testing-library/react";
import BatchEditAdministrative from "./Administrative";
import {
  renderWithRouterApollo,
  setupCachedCodeListsLocalStorage,
} from "../../../services/testing-helpers";
import {
  codeListLibraryUnitMock,
  codeListPreservationLevelMock,
  codeListStatusMock,
  codeListVisibilityMock,
} from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";

const items = ["ABC123", "ZYC889"];

describe("BatchEditAdministrative component", () => {
  function setupTest() {
    setupCachedCodeListsLocalStorage();
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <BatchEditAdministrative items={items} />
      </BatchProvider>,
      {
        mocks: [
          codeListLibraryUnitMock,
          codeListPreservationLevelMock,
          codeListStatusMock,
          codeListVisibilityMock,
        ],
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
      expect(
        getByTestId("batch-edit-administrative-sticky-header")
      ).toBeInTheDocument();
    });
  });

  it("renders project metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("project-metadata")).toBeInTheDocument();
    });
  });

  it("renders project status metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("project-status-metadata")).toBeInTheDocument();
    });
  });
});
