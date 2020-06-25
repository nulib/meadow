import React from "react";
import Work from "./Work";
import { waitFor } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { mockWork } from "./work.gql.mock";
import { IIIF_SERVER_URL } from "../IIIF/iiif.gql";
import {
  codeListAuthorityMock,
  codeListMarcRelatorMock,
} from "./controlledVocabulary.gql.mock";

const mocks = [
  {
    request: {
      query: IIIF_SERVER_URL,
    },
    result: {
      data: {
        iiifServerUrl: {
          url: "http://localhost:8184/iiif/2/",
        },
      },
    },
  },
  codeListAuthorityMock,
  codeListMarcRelatorMock,
];

describe("Work component", () => {
  function setupTests() {
    return renderWithRouterApollo(<Work work={mockWork} />, { mocks });
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders the viewer and tabs", async () => {
    const { getByTestId } = setupTests();

    await waitFor(() => {
      expect(getByTestId("viewer")).toBeInTheDocument();
      expect(getByTestId("tabs")).toBeInTheDocument();
    });
  });
});
