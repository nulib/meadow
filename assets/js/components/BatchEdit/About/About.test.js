import React from "react";
import { waitFor } from "@testing-library/react";
import BatchEditAbout from "./About";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import {
  codeListLicenseMock,
  codeListRightsStatementMock,
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
} from "../../Work/controlledVocabulary.gql.mock";

const items = ["ABC123", "ZYC889"];

describe("BatchEditAbout component", () => {
  function setupTest() {
    return renderWithRouterApollo(<BatchEditAbout items={items} />, {
      mocks: [
        codeListLicenseMock,
        codeListMarcRelatorMock,
        codeListRightsStatementMock,
        codeListSubjectRoleMock,
      ],
    });
  }

  it("renders Batch Edit About form", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-about-form")).toBeInTheDocument();
    });
  });

  it("renders the sticky header", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-about-sticky-header")).toBeInTheDocument();
    });
  });

  it("renders the warning notification", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(
        getByTestId("batch-edit-warning-notification")
      ).toBeInTheDocument();
    });
  });

  it("renders core metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("core-metadata-wrapper")).toBeInTheDocument();
    });
  });

  it("renders descriptive metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("descriptive-metadata-wrapper")).toBeInTheDocument();
    });
  });
});
