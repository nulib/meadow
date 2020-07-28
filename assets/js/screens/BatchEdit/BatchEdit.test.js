import React from "react";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import ScreensBatchEdit from "./BatchEdit";
import {
  codeListAuthorityMock,
  codeListLicenseMock,
  codeListMarcRelatorMock,
  codeListRightsStatementMock,
  codeListSubjectRoleMock,
} from "../../components/Work/controlledVocabulary.gql.mock";

describe("BatchEdit component", () => {
  function setupComponent() {
    return renderWithRouterApollo(<ScreensBatchEdit />, {
      mocks: [
        codeListAuthorityMock,
        codeListLicenseMock,
        codeListMarcRelatorMock,
        codeListRightsStatementMock,
        codeListSubjectRoleMock,
      ],
      // Mocks sending in 2 items to Batch Edit component via react-router-dom "state"
      state: { resultStats: { numberOfResults: 5 } },
    });
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
    const { getByTestId, queryByText, debug } = setupComponent();

    await waitFor(() => {
      expect(getByTestId("batch-edit-title")).toBeInTheDocument();
      expect(getByTestId("num-results")).toBeInTheDocument();
      expect(queryByText("Editing 5 rows")).toBeInTheDocument();
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
