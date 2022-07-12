import { screen, render } from "@testing-library/react";
import React from "react";
import UIDownloadAll from "@js/components/UI/Modal/DownloadAll";
import userEvent from "@testing-library/user-event";
import { workArchiverEndpointMock } from "@js/components/Work/work.gql.mock";
import { renderWithApollo } from "@js/services/testing-helpers";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { mockUser } from "@js/components/Auth/auth.gql.mock";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("UIDownloadAll component", () => {
  beforeEach(() => {
    renderWithApollo(<UIDownloadAll workId="asdf" />, {
      mocks: [workArchiverEndpointMock],
    });
  });

  it("renders the Download All button", async () => {
    expect(await screen.findByTestId("download-all-button"));
  });

  it("toggles modal display", async () => {
    const user = userEvent.setup();
    const downloadButton = await screen.findByTestId("download-all-button");
    const cancelButton = await screen.findByTestId("cancel-button");
    const modalWrapper = await screen.findByTestId("download-all-modal");

    await user.click(downloadButton);
    expect(modalWrapper).toHaveClass("is-active");

    await user.click(cancelButton);
    expect(modalWrapper).not.toHaveClass("is-active");

    await user.click(downloadButton);
    expect(modalWrapper).toHaveClass("is-active");
  });

  it("renders user email", async () => {
    expect(await screen.findByTestId("email"));
  });

  it("renders radio buttons for IIIF image sizes", async () => {
    const radioWrapperEl = await screen.findByTestId("radio-image-size");
    expect(radioWrapperEl.childNodes).toHaveLength(3);
  });

  it("renders the submit and cancel buttons", async () => {
    expect(await screen.findByTestId("cancel-button"));
    expect(await screen.findByTestId("submit-button"));
  });
});
