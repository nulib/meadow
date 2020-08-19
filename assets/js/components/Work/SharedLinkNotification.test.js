import React from "react";
import { render } from "@testing-library/react";
import WorkSharedLinkNotification from "./SharedLinkNotification";
import moment from "moment";

const createSharedLink = {
  expires: "2020-09-02T20:04:40.166275Z",
  sharedLinkId: "387d65b6-93e5-4dbc-b65d-b072ecf661c9",
  workId: "1a110eed-6b5a-470f-a45b-fae4293523b5",
};

describe("WorkSharedLinkNotification component", () => {
  it("renders the component", () => {
    const { getByTestId } = render(
      <WorkSharedLinkNotification linkData={createSharedLink} />
    );
    expect(getByTestId("notification-shared-link")).toBeInTheDocument();
  });

  it("renders the success message", () => {
    const { getByTestId, getByText, debug } = render(
      <WorkSharedLinkNotification linkData={createSharedLink} />
    );

    expect(
      getByText("Your shared link has been created successfully")
    ).toBeInTheDocument();
  });

  it("renders the link url and expiration dates", () => {
    const { getByTestId } = render(
      <WorkSharedLinkNotification linkData={createSharedLink} />
    );

    expect(getByTestId("link-url")).toHaveTextContent(
      createSharedLink.sharedLinkId
    );

    const formattedDate = moment(createSharedLink.expires).format(
      "MMM DD, YYYY h:mm A"
    );

    expect(getByTestId("link-date")).toHaveTextContent(formattedDate);
  });
});
