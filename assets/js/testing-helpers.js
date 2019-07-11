import React from "react";
import { MemoryRouter, Router } from "react-router-dom";
import { render } from "@testing-library/react";
import { createMemoryHistory } from "history";

export function renderWithRouter(
  ui,
  {
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] })
  } = {}
) {
  return {
    ...render(<Router history={history}>{ui}</Router>),
    history
  };
}
