import {
  MOCK_WORK_ID,
  dcApiTokenMock,
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

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [
  dcApiTokenMock,
  getWorkMock,
  iiifServerUrlMock,
  ...allCodeListMocks,
];

jest.mock("@samvera/clover-iiif/viewer", () => {
  return {
    __esModule: true,
    default: (props) => {
      // Call the canvasCallback with a string when the component is rendered
      if (props.canvasCallback) {
        props.canvasCallback(
          "https://mat.dev.rdc.library.northwestern.edu:3002/works/a1239c42-6e26-4a95-8cde-0fa4dbf0af6a?as=iiif/canvas/access/0"
        );
      }
      return <div></div>;
    },
  };
});

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
