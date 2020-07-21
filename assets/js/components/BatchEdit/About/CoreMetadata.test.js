import React from "react";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import BatchEditAboutCoreMetadata from "./CoreMetadata";
import {
  codeListAuthorityMock,
  codeListLicenseMock,
  codeListRightsStatementMock,
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
} from "../../Work/controlledVocabulary.gql.mock";

const registerMock = jest.fn();

describe("BatchEditAboutCoreMetadata component", () => {
  function setupTest() {
    return renderWithRouterApollo(
      <BatchEditAboutCoreMetadata register={registerMock} />,
      { mocks: [codeListLicenseMock, codeListRightsStatementMock] }
    );
  }
  it("renders the component", async () => {
    let { queryByTestId } = setupTest();

    await waitFor(() => {
      expect(queryByTestId("core-metadata")).toBeInTheDocument();
    });
  });

  it("renders expected core metadata fields", async () => {
    let { getByTestId } = setupTest();

    await waitFor(() => {
      const itemTestIds = [
        "title",
        "description",
        "rights-statement",
        "date-created",
        "license",
      ];
      for (let item of itemTestIds) {
        expect(getByTestId(item)).toBeInTheDocument();
      }
    });
  });
});
