import React from "react";
import { waitFor } from "@testing-library/react";
import BatchEditAbout from "./About";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import {
  codeListAuthorityMock,
  codeListLicenseMock,
  codeListRightsStatementMock,
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
} from "../../Work/controlledVocabulary.gql.mock";
import { BatchProvider } from "../../../context/batch-edit-context";

const items = ["ABC123", "ZYC889"];

describe("BatchEditAbout component", () => {
  function setupTest() {
    return renderWithRouterApollo(
      <BatchProvider value={null}>
        <BatchEditAbout items={items} />
      </BatchProvider>,
      {
        mocks: [
          codeListAuthorityMock,
          codeListLicenseMock,
          codeListMarcRelatorMock,
          codeListRightsStatementMock,
          codeListSubjectRoleMock,
        ],
      }
    );
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
      expect(getByTestId("core-metadata")).toBeInTheDocument();
    });
  });

  it("renders controlled metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("controlled-metadata")).toBeInTheDocument();
    });
  });

  it("renders Identifiers metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("identifiers-metadata")).toBeInTheDocument();
    });
  });

  it("renders physical metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("physical-metadata")).toBeInTheDocument();
    });
  });

  it("renders rights metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("rights-metadata")).toBeInTheDocument();
    });
  });

  it("renders uncontrolled metadata component", async () => {
    const { getByTestId } = setupTest();
    await waitFor(() => {
      expect(getByTestId("uncontrolled-metadata")).toBeInTheDocument();
    });
  });
});
