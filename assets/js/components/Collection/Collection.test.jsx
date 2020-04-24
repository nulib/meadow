import React from "react";
import { render } from "@testing-library/react";
import Collection from "./Collection";

const props = {
  adminEmail: "test@test.com",
  description: "Test arrays keyword arrays arrays arrays arrays",
  featured: false,
  findingAidUrl: "http://go.com",
  id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
  keywords: ["yo", "foo", "bar", "dude", "hey"],
  name: "Ima collection",
  published: false,
  works: [],
};

it("renders Collection component", async () => {
  const { getByTestId } = render(<Collection {...props} />);
  const collectionSection = getByTestId("collection");
  expect(collectionSection).toBeInTheDocument();
});

it("renders collection properties", async () => {
  const { getByText } = render(<Collection {...props} />);
  expect(getByText("test@test.com")).toBeInTheDocument();
  expect(
    getByText("Test arrays keyword arrays arrays arrays arrays")
  ).toBeInTheDocument();
});
