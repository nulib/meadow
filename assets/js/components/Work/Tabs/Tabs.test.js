import React from "react";
import WorkTabs from "./Tabs";
import { fireEvent, waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import { mockWork } from "../work.gql.mock";
import { iiifServerUrlMock } from "../../IIIF/iiif.gql.mock";
import {
  authorityMock,
  codeListLicenseMock,
  marcRelatorMock,
  codeListPreservationLevelMock,
  codeListRightsStatementMock,
  subjectMock,
  codeListStatusMock,
  codeListVisibilityMock,
  codeListRelatedUrlMock,
} from "../controlledVocabulary.gql.mock";
import {
  getCollectionMock,
  getCollectionsMock,
} from "../../Collection/collection.gql.mock";

const mocks = [
  codeListLicenseMock,
  codeListPreservationLevelMock,
  codeListRightsStatementMock,
  codeListStatusMock,
  codeListVisibilityMock,
  getCollectionsMock,
  iiifServerUrlMock,
  codeListRelatedUrlMock,
];

describe("Tabs component", () => {
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
  function setupTests() {
    prepLocalStorage();
    return renderWithRouterApollo(<WorkTabs work={mockWork} />, { mocks });
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders tab section and all four tabs: About, Administrative, Structure, and Preservation", async () => {
    const { getByTestId } = setupTests();

    await waitFor(() => {
      expect(getByTestId("tabs")).toBeInTheDocument();
      expect(getByTestId("tab-about")).toBeInTheDocument();
      expect(getByTestId("tab-administrative")).toBeInTheDocument();
      expect(getByTestId("tab-structure")).toBeInTheDocument();
      expect(getByTestId("tab-preservation")).toBeInTheDocument();
    });
  });

  it("renders About tab content by default", async () => {
    const { queryByTestId } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("tab-about-content")).toBeVisible();
      expect(queryByTestId("structure-content")).toBeNull();
    });
  });

  it("renders a tab active when clicking on a tab nav item", async () => {
    const { queryByTestId, debug } = setupTests();

    await waitFor(() => {
      expect(queryByTestId("tab-about-content")).not.toHaveClass("is-hidden");

      fireEvent.click(queryByTestId("tab-administrative"));

      expect(queryByTestId("tab-administrative-content")).not.toHaveClass(
        "is-hidden"
      );
      expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");

      fireEvent.click(queryByTestId("tab-preservation"));

      expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");
      expect(queryByTestId("tab-administrative-content")).toHaveClass(
        "is-hidden"
      );
      expect(queryByTestId("tab-structure-content")).toHaveClass("is-hidden");
      expect(queryByTestId("tab-preservation-content")).not.toHaveClass(
        "is-hidden"
      );
    });
  });
});
