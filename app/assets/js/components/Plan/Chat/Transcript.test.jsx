import React from "react";
import { render, screen } from "@testing-library/react";
import PlanChatTranscript from "./Transcript";

/**
 * Mock PlanChatMessage to capture props passed to it
 */
jest.mock("@js/components/Plan/Chat/Message", () => ({
  __esModule: true,
  default: ({ content, isUser, type }) => (
    <div data-testid="mock-message">
      {type}:{isUser ? "user" : "ai"}:{content}
    </div>
  ),
}));

describe("PlanChatTranscript", () => {
  const messages = [
    { content: "Hello", isUser: true, type: "message" },
    { content: "Hi there", isUser: false, type: "message" },
    { content: "Error happened", isUser: false, type: "error" },
  ];

  test("renders wrapper with class 'chat-transcript'", () => {
    const { container } = render(<PlanChatTranscript messages={messages} />);
    expect(container.firstChild).toHaveClass("chat-transcript");
  });

  test("renders one PlanChatMessage per message", () => {
    render(<PlanChatTranscript messages={messages} />);
    const renderedMessages = screen.getAllByTestId("mock-message");
    expect(renderedMessages).toHaveLength(messages.length);
  });

  test("passes correct props to each PlanChatMessage", () => {
    render(<PlanChatTranscript messages={messages} />);
    const renderedMessages = screen.getAllByTestId("mock-message");

    /**
     * Each message should render with correct type, isUser, and content
     */
    expect(renderedMessages[0].textContent).toBe("message:user:Hello");
    expect(renderedMessages[1].textContent).toBe("message:ai:Hi there");
    expect(renderedMessages[2].textContent).toBe("error:ai:Error happened");
  });

  test("renders nothing when messages is empty", () => {
    render(<PlanChatTranscript messages={[]} />);
    expect(screen.queryByTestId("mock-message")).toBeNull();
  });

  test("handles undefined or null messages gracefully", () => {
    const { container, rerender } = render(
      <PlanChatTranscript messages={undefined} />,
    );
    expect(container.querySelector(".chat-transcript")).toBeInTheDocument();
    expect(screen.queryByTestId("mock-message")).toBeNull();

    rerender(<PlanChatTranscript messages={null} />);
    expect(screen.queryByTestId("mock-message")).toBeNull();
  });
});
