import React from "react";
import { screen } from "@testing-library/react";
import WorkPublicLinkNotification from "./PublicLinkNotification";
import { renderWithApollo } from "@js/services/testing-helpers";
import {
  digitalCollectionsUrlMock,
  mockDCUrl,
} from "@js/components/UI/ui.gql.mock";

describe("WorkPublicLinkNotification component", () => {
  beforeEach(() => {
    renderWithApollo(<WorkPublicLinkNotification workId="ABC123" />, {
      mocks: [digitalCollectionsUrlMock],
    });
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("notification-public-link"));
  });

  it("renders the success message", async () => {
    expect(await screen.findByTestId("notification-public-link"));
    expect(
      await screen.findByText(
        "This link is publicly available on Digital Collections."
      )
    );
  });

  it("renders the link url", async () => {
    expect(await screen.findByTestId("link-url")).toHaveTextContent(
      `${mockDCUrl}items/ABC123`
    );
  });
});
