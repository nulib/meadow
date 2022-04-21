import React from "react";
import GlobalSearch from "./GlobalSearch";
import { render } from "@testing-library/react";

it("renders without crashing", () => {
  render(<GlobalSearch />);
});
