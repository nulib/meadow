import { render, screen } from "@testing-library/react";

import React from "react";
import UIVisibilityTag from "./VisibilityTag";

describe("Visibility Tag component", () => {
  it("renders the correct tag when passed in Index model data", () => {
    render(<UIVisibilityTag visibility="Institution" />);
    expect(screen.getByText("Institution")).toBeInTheDocument();
  });

  it("renders the Institution tag when passed in GraphQL model data", () => {
    render(
      <UIVisibilityTag
        visibility={{
          __typename: "CodedTerm",
          id: "AUTHENTICATED",
          label: "Institution",
        }}
      />
    );
    expect(screen.getByText("Institution")).toBeInTheDocument();
  });

  it("renders the Private tag when passed in GraphQL model data", () => {
    render(
      <UIVisibilityTag
        visibility={{
          __typename: "CodedTerm",
          id: "RESTRICTED",
          label: "Private",
        }}
      />
    );
    expect(screen.getByText("Private")).toBeInTheDocument();
  });
});
