import React from "react";
import { render, cleanup } from "@testing-library/react";
// this adds custom jest matchers from jest-dom
import "@testing-library/jest-dom/extend-expect";
import HomePage from "./Home";
import { renderWithRouter } from "../../services/testing-helpers";

jest.mock("../../services/elasticsearch");

afterEach(cleanup);

test.skip("Home page component renders", () => {
  const { container } = renderWithRouter(<HomePage />);
  expect(container).toBeTruthy();
});
