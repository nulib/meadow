import React from "react";
import BatchEditAboutDescriptiveMetadata from "./DescriptiveMetadata";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "../../../services/testing-helpers";
import {
  codeListMarcRelatorMock,
  codeListSubjectRoleMock,
  codeListAuthorityMock,
} from "../../Work/controlledVocabulary.gql.mock";

describe("BatchEditAboutDescriptiveMetadata component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(<BatchEditAboutDescriptiveMetadata />, {
      mocks: [
        codeListAuthorityMock,
        codeListMarcRelatorMock,
        codeListSubjectRoleMock,
      ],
    });
  });

  it("renders the component", () => {
    expect(screen.queryByTestId("descriptive-metadata"));
  });

  // TODO: Add tests here...
});
