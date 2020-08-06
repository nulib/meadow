import React from "react";
import BatchEditTabs from "./Tabs";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import {
  authorityMock,
  codeListLicenseMock,
  marcRelatorMock,
  codeListRightsStatementMock,
  codeListSubjectRoleMock,
  codeListRelatedUrlMock,
  subjectMock,
} from "../Work/controlledVocabulary.gql.mock.js";
import { BatchProvider } from "../../context/batch-edit-context";

const items = ["ABC123", "ZYC889"];

describe("BatchEditTabs component", () => {
  function prepLocalStorage() {
    localStorage.setItem(
      "codeLists",
      JSON.stringify({
        MARC_RELATOR: marcRelatorMock,
        AUTHORITY: authorityMock,
        SUBJECT_ROLE: subjectMock,
      })
    );
  }
  function setupTest() {
    prepLocalStorage();
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <BatchEditTabs items={items} />
      </BatchProvider>,
      {
        mocks: [
          codeListAuthorityMock,
          codeListLicenseMock,
          codeListMarcRelatorMock,
          codeListRightsStatementMock,
          codeListSubjectRoleMock,
          codeListRelatedUrlMock,
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
