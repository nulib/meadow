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

  it("renders collection image modal", async () => {
    const { getByTestId, debug } = setupTest();
    await waitFor(() => {
      expect(getByTestId("batch-edit-about-form")).toBeInTheDocument();
    });
  });
});
