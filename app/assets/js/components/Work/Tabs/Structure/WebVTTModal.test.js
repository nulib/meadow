import React from "react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

// mock Apollo useMutation so we don't need an ApolloProvider
jest.mock("@apollo/client", () => {
  const actual = jest.requireActual("@apollo/client");
  return {
    ...actual,
    // Return a tuple like the real hook: [mutateFn, result]
    useMutation: () => [
      jest.fn().mockResolvedValue({ data: { updateFileSet: { id: "fake" } } }),
      { loading: false, error: undefined, data: undefined },
    ],
  };
});

import WorkTabsStructureWebVTTModal from "./WebVTTModal";
import { WorkProvider } from "@js/context/work-context";

// --- Mock useParams() ---
jest.mock("react-router-dom", () => {
  const actual = jest.requireActual("react-router-dom");
  return {
    ...actual,
    useParams: () => ({ workId: "work-123" }), // adjust if your component needs more params
  };
});

const validWebVTT = `WEBVTT

1
00:00:00.000 --> 00:00:01.000
Hello, world!

2
00:00:01.000 --> 00:00:02.000
Goodbye, world!
`;

const invalidWebVTT = `1
00:00:00.000 --> 00:00:01.000
Hello, world!

2
0000:01.000 --> 00:00:02.000
Goodbye, world!
`;

describe("WorkTabsStructureWebVTTModal", () => {
  it("renders without crashing", () => {
    render(
      <WorkProvider>
        <WorkTabsStructureWebVTTModal isActive={true} />
      </WorkProvider>,
    );
    expect(screen.getByRole("textbox")).toBeInTheDocument();
  });

  it("displays a valid message for valid VTT inputs", async () => {
    const user = userEvent.setup();
    render(
      <WorkProvider>
        <WorkTabsStructureWebVTTModal isActive={true} />
      </WorkProvider>,
    );

    const textarea = screen.getByRole("textbox");
    await user.clear(textarea);
    await user.type(textarea, validWebVTT);

    const successNotification = await screen.findByText(/WebVTT is valid/i);
    expect(successNotification).toBeInTheDocument();
  });

  it("displays validation errors for invalid VTT as an ordered list", async () => {
    const user = userEvent.setup();
    render(
      <WorkProvider>
        <WorkTabsStructureWebVTTModal isActive={true} />
      </WorkProvider>,
    );

    const textarea = screen.getByRole("textbox");
    await user.clear(textarea);
    await user.type(textarea, invalidWebVTT);

    // Error notification shows
    const errorNotification = await screen.findByText(/WebVTT is not valid/i);
    expect(errorNotification).toBeInTheDocument();

    // Error list items show up
    const items = await screen.findAllByRole("listitem");
    expect(items.length).toBeGreaterThan(0);
    expect(items[0].textContent).toMatch(
      `Line 1, column : No valid signature. (File needs to start with "WEBVTT".)`,
    );

    expect(items[1].textContent).toMatch(
      `Line 2, column : No blank line after the signature.`,
    );

    expect(items[2].textContent).toMatch(
      `Line 6, column 8: No seconds found or minutes is greater than 59.`,
    );
  });
});
