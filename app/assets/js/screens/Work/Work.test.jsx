import {
  MOCK_WORK_ID,
  getIIIFManifestHeaders,
  getWorkMock,
} from "@js/components/Work/work.gql.mock";

import { BatchProvider } from "@js/context/batch-edit-context";
import React from "react";
import { Route } from "react-router-dom";
import ScreensWork from "./Work";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";
import { iiifServerUrlMock } from "@js/components/IIIF/iiif.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { screen } from "@testing-library/react";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

// Mock the getManifest call from the child Work component
jest.mock("@js/services/get-manifest");

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [
  getWorkMock,
  iiifServerUrlMock,
  getIIIFManifestHeaders,
  ...allCodeListMocks,
];

describe("ScreensWork component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <BatchProvider>
        <Route path="/work/:id" component={ScreensWork} />
      </BatchProvider>,
      {
        mocks,
        route: `/work/${MOCK_WORK_ID}`,
      }
    );
  });

  it("renders", async () => {
    const el = await screen.findByTestId("work-hero");
    expect(el);
  });

  it("renders breadcrumbs", async () => {
    const crumbsEl = await screen.findByTestId("work-breadcrumbs");
    expect(crumbsEl).toBeInTheDocument();
  });

  it("renders work title", async () => {
    const el = await screen.findByTestId("work-page-title");
    expect(el).toHaveTextContent("Work title here");
  });

  it("renders the correct work header info", async () => {
    expect(await screen.findByTestId("work-header-id")).toHaveTextContent("Id");
    expect(screen.getByTestId("work-header-ark")).toHaveTextContent("Ark");
    expect(
      screen.getByTestId("work-header-accession-number")
    ).toHaveTextContent("Accession number");
  });
});
