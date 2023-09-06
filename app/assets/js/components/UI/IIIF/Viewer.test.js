import { screen, waitFor } from "@testing-library/react";

import IIIFViewer from "./Viewer";
import React from "react";
import { dcApiTokenMock } from "@js/components/Work/work.gql.mock";
import { WorkProvider } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const initialState = {
  activeMediaFileSet: mockFileSets[0],
  webVttModal: {
    fileSetId: null,
    isOpen: false,
    webVttString: "",
  },
  workType: "VIDEO",
};

const mocks = [dcApiTokenMock];

jest.mock("@js/services/get-api-response-headers");
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

describe("IIIFViewer component", () => {
  it("renders", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={initialState}>
        <IIIFViewer
          fileSet={mockFileSets[0]}
          fileSets={[...mockFileSets]}
          iiifContent="ABC123"
          workTypeId="IMAGE"
        />
      </WorkProvider>,
      { mocks }
    );
    expect(await screen.findByTestId("iiif-viewer"));
  });

  it("renders the poster selector button for a Video work type", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={initialState}>
        <IIIFViewer
          fileSet={mockFileSets[0]}
          fileSets={[...mockFileSets]}
          iiifContent="ABC123"
          workTypeId="VIDEO"
        />
      </WorkProvider>,
      { mocks }
    );
    expect(await screen.findByTestId("set-poster-image-button"));
  });

  it("does not render the poster selector button for an Audio work type", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={{ ...initialState }}>
        <IIIFViewer
          fileSet={mockFileSets[0]}
          fileSets={[...mockFileSets]}
          iiifContent="ABC123"
          workTypeId="AUDIO"
        />
      </WorkProvider>
    );
    await waitFor(() => {
      expect(
        screen.queryByTestId("set-poster-image-button")
      ).not.toBeInTheDocument();
    });
  });
});
