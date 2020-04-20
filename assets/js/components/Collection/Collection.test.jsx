import React from "react";
import { render } from "@testing-library/react";
import { wait, waitForElement } from "@testing-library/react";
import Collection from "./Collection";

const mocks = {
  adminEmail: "test@test.com",
  description: "Test arrays keyword arrays arrays arrays arrays",
  featured: false,
  findingAidUrl: "http://go.com",
  id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
  keywords: ["yo", "foo", "bar", "dude", "hey"],
  name: "Ima collection",
  published: false,
  works: []
};

it("renders collection section", async () => {
  const { getByTestId, getByText } = render(<Collection {...mocks} />);
  const collectionSection = await waitForElement(() =>
    getByTestId("collection")
  );
  await wait();
  expect(collectionSection).toBeInTheDocument();
});

it("renders collection properties", async () => {
  const { getByText } = render(<Collection {...mocks} />);
  expect(getByText("test@test.com")).toBeInTheDocument();
  expect(
    getByText("Test arrays keyword arrays arrays arrays arrays")
  ).toBeInTheDocument();
});
