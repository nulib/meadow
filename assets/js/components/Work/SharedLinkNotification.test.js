import React from "react";
import { screen } from "@testing-library/react";
import WorkSharedLinkNotification from "./SharedLinkNotification";
import moment from "moment";
import { renderWithApollo } from "@js/services/testing-helpers";
import {
  digitalCollectionsUrlMock,
  mockDCUrl,
} from "@js/components/UI/ui.gql.mock";

const createSharedLink = {
  expires: "2020-09-02T20:04:40.166275Z",
  sharedLinkId: "387d65b6-93e5-4dbc-b65d-b072ecf661c9",
  workId: "1a110eed-6b5a-470f-a45b-fae4293523b5",
};

describe("WorkSharedLinkNotification component", () => {
  beforeEach(() => {
    renderWithApollo(
      <WorkSharedLinkNotification linkData={createSharedLink} />,
      {
        mocks: [digitalCollectionsUrlMock],
      }
    );
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("notification-shared-link"));
  });

  it("renders the success message", async () => {
    expect(
      await screen.findByText(
        "Your shared link has been created successfully and will expire:"
      )
    );
  });

  it("renders the link url and expiration dates", async () => {
    expect(await screen.findByTestId("link-url")).toHaveTextContent(
      `${mockDCUrl}shared/${createSharedLink.sharedLinkId}`
    );

    const formattedDate = moment(createSharedLink.expires).format(
      "MMM DD, YYYY h:mm A"
    );

    expect(await screen.findByTestId("link-date")).toHaveTextContent(
      formattedDate
    );
  });
});
