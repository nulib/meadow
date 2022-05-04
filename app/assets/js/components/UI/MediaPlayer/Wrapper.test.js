import React from "react";
import { screen, waitFor } from "@testing-library/react";
import MediaPlayerWrapper from "./Wrapper";
import { WorkProvider } from "@js/context/work-context";
import { mockFileSets } from "@js/mock-data/filesets";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

import { mockUser } from "@js/components/Auth/auth.gql.mock";
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
  workTypeId: "VIDEO",
};

describe("MediaPlayerWrapper component", () => {
  it("renders", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={initialState}>
        <MediaPlayerWrapper fileSets={[...mockFileSets]} manifestId="ABC123" />
      </WorkProvider>
    );
    expect(await screen.findByTestId("media-player-wrapper"));
  });

  it("renders the poster selector button for a Video work type", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={initialState}>
        <MediaPlayerWrapper
          fileSets={[...mockFileSets]}
          manifestId="ABC123"
          canvasReady={true}
        />
      </WorkProvider>
    );
    expect(await screen.findByTestId("set-poster-image-button"));
  });

  it("does not render the poster selector button for an Audio work type", async () => {
    renderWithRouterApollo(
      <WorkProvider initialState={{ ...initialState, workTypeId: "AUDIO" }}>
        <MediaPlayerWrapper fileSets={[...mockFileSets]} manifestId="ABC123" />
      </WorkProvider>
    );
    await waitFor(() => {
      expect(
        screen.queryByTestId("set-poster-image-button")
      ).not.toBeInTheDocument();
    });
  });
});
