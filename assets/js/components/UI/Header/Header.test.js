import React from "react";
import { renderWithRouterApollo } from "../../../testing-helpers";
import Header from "./Header";
import { AuthContext } from "../../Auth/Auth";

const me = {
  displayName: "Izzy Stradlin",
  email: "izzy@northwestern.edu",
  username: "izzy0137"
};

function setupProviderTests() {
  return renderWithRouterApollo(
    <AuthContext.Provider value={me}>
      <Header />
    </AuthContext.Provider>
  );
}

it("renders without crashing", () => {
  renderWithRouterApollo(<Header />);
});

it("renders the global search bar", () => {
  const { getByTestId } = setupProviderTests();
  expect(getByTestId("global-search")).toBeInTheDocument();
});

it("renders the user nav dropdown", () => {
  const { getByTestId, debug } = renderWithRouterApollo(<Header />);
  expect(getByTestId("header-nav")).toBeInTheDocument();
});
