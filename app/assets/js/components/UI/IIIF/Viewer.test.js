import { screen, waitFor } from "@testing-library/react";

import IIIFViewer from "./Viewer";
import React from "react";
import { dcApiTokenMock } from "@js/components/Work/work.gql.mock";
import { WorkProvider } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

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
  dcApiToken: "asd8967asd89asc78234891289nkldsnn89123",
};

const mocks = [dcApiTokenMock];

let mockCanvasFileSetId = mockFileSets[0].id;

jest.mock("@samvera/clover-iiif/viewer", () => {
  return {
    __esModule: true,
    default: (props) => {
      // Call the canvasIdCallback with a string when the component is rendered
      if (props.canvasIdCallback) {
        props.canvasIdCallback(
          `https://mat.dev.rdc.library.northwestern.edu:3002/file-sets/${mockCanvasFileSetId}?as=iiif`,
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
      { mocks },
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
      { mocks },
    );
    expect(await screen.findByTestId("set-poster-image-button"));
  });

  it("keeps the poster selector button visible when the canvas callback can't resolve a file set", async () => {
    mockCanvasFileSetId = "does-not-exist"; // no matching mock file set id

    renderWithRouterApollo(
      <WorkProvider initialState={initialState}>
        <IIIFViewer
          fileSet={mockFileSets[0]}
          fileSets={[...mockFileSets]}
          iiifContent="ABC123"
          workTypeId="VIDEO"
        />
      </WorkProvider>,
      { mocks },
    );

    expect(
      await screen.findByTestId("set-poster-image-button"),
    ).toBeInTheDocument();

    mockCanvasFileSetId = mockFileSets[0].id;
  });

  it("updates the active file set when the canvas callback resolves a matching file set id", async () => {
    mockCanvasFileSetId = mockFileSets[2].id;

    renderWithRouterApollo(
      <WorkProvider
        initialState={{ ...initialState, activeMediaFileSet: mockFileSets[0] }}
      >
        <IIIFViewer
          fileSet={mockFileSets[0]}
          fileSets={[...mockFileSets]}
          iiifContent="ABC123"
          workTypeId="VIDEO"
        />
      </WorkProvider>,
      { mocks },
    );

    // The poster button's label reflects the *active* file set, so seeing
    // file set 2's label confirms the callback re-resolved by id.
    expect(
      await screen.findByText(mockFileSets[2].coreMetadata.label),
    ).toBeInTheDocument();

    mockCanvasFileSetId = mockFileSets[0].id;
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
      </WorkProvider>,
    );
    await waitFor(() => {
      expect(
        screen.queryByTestId("set-poster-image-button"),
      ).not.toBeInTheDocument();
    });
  });
});
