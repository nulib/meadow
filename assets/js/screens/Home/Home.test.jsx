import React from "react";
import { render, cleanup } from "@testing-library/react";
// this adds custom jest matchers from jest-dom
import "@testing-library/jest-dom/extend-expect";
import HomePage from "./Home";
import { renderWithRouter } from "../../testing-helpers";

afterEach(cleanup);

test("Home page component renders", () => {
  const { container } = renderWithRouter(<HomePage />);
  expect(container).toBeTruthy();
});
