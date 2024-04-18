import { cleanup, render } from "@testing-library/react";

import HomePage from "./Home";
import React from "react";
import { renderWithRouter } from "../../services/testing-helpers";

jest.mock("../../services/elasticsearch");

afterEach(cleanup);

test.skip("Home page component renders", () => {
  const { container } = renderWithRouter(<HomePage />);
  expect(container).toBeTruthy();
});
