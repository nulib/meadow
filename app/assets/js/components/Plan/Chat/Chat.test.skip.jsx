import React from "react";
import { render, screen, fireEvent, act } from "@testing-library/react";
import PlanChat from "./Chat";

/**
 * Set up global mocks for requestAnimationFrame and ResizeObserver
 */
beforeAll(() => {
  global.requestAnimationFrame = (cb) => setTimeout(cb, 0);
  global.cancelAnimationFrame = (id) => clearTimeout(id);

  /**
   * Mock ResizeObserver
   */
  class MockResizeObserver {
    constructor(cb) {
      this.cb = cb;
      this.el = null;
    }
    observe(el) {
      this.el = el;
      MockResizeObserver.instances.add(this);
    }
    disconnect() {
      MockResizeObserver.instances.delete(this);
    }
    __trigger() {
      this.cb([{ target: this.el }]);
    }
  }
  MockResizeObserver.instances = new Set();
  global.ResizeObserver = MockResizeObserver;
});

/**
 * Mocks
 */
let mockSendChatMessage;
let mockSendHookError;

let mockSubscriptionData;
let mockSubscriptionHookError;

jest.mock("uuid", () => ({ v4: () => "conv-123" }));

/**
 * Expose messages via data-testid
 */
jest.mock("@js/components/Plan/Chat/Transcript", () => ({
  __esModule: true,
  default: ({ messages = [] }) => (
    <div data-testid="transcript">
      {messages.map((m, i) => (
        <div key={i} data-testid={`msg-${i}`}>
          {m.type}:{m.isUser ? "user" : "ai"}:{m.content}
        </div>
      ))}
    </div>
  ),
}));

/**
 * Mock the form to avoid dealing with textarea events here
 */
jest.mock("@js/components/Plan/Chat/Form", () => ({
  __esModule: true,
  default: ({ showScrollButton, onScrollToBottom, onSubmitMessage }) => (
    <div data-testid="form">
      <span data-testid="scroll-button-visible">
        {showScrollButton ? "true" : "false"}
      </span>
      <button data-testid="scroll-to-bottom" onClick={onScrollToBottom}>
        scroll
      </button>
      <button
        data-testid="send-btn"
        onClick={() => onSubmitMessage("User says hi")}
      >
        send
      </button>
    </div>
  ),
}));

/**
 * Mock the hooks
 */
jest.mock("@js/hooks/useSendChatMessage", () => ({
  useSendChatMessage: () => ({
    sendChatMessage: mockSendChatMessage,
    error: mockSendHookError,
    data: undefined,
    loading: false,
  }),
}));

jest.mock("@js/hooks/useChatResponse", () => ({
  useChatResponse: () => ({
    data: mockSubscriptionData,
    error: mockSubscriptionHookError,
    loading: false,
  }),
}));

const initialMessage = {
  content: "hello initial",
  isUser: true,
  type: "message",
};
const query = "the-query";
const originalError = console.error;

beforeEach(() => {
  mockSendChatMessage = jest.fn().mockResolvedValue({});
  mockSendHookError = undefined;
  mockSubscriptionData = null;
  mockSubscriptionHookError = undefined;
  console.error = jest.fn();
});

afterEach(() => {
  jest.clearAllMocks();
  console.error = originalError;
});
/**
 * Helpers to control scroll geometry in tests
 */
function setScroll(el, { scrollHeight, clientHeight, scrollTop }) {
  Object.defineProperty(el, "scrollHeight", {
    value: scrollHeight,
    configurable: true,
  });
  Object.defineProperty(el, "clientHeight", {
    value: clientHeight,
    configurable: true,
  });
  Object.defineProperty(el, "scrollTop", {
    get: () => setScroll._top ?? 0,
    set: (v) => (setScroll._top = v),
    configurable: true,
  });
  setScroll._top = scrollTop ?? 0;
}
function getChatBody() {
  return document.querySelector(".chat-body");
}

/**
 * Tests
 */
test("renders initial message and no scroll button initially", () => {
  render(<PlanChat initialMessage={initialMessage} query={query} />);
  expect(screen.getByTestId("msg-0").textContent).toBe(
    "message:user:hello initial",
  );
  expect(screen.getByTestId("scroll-button-visible").textContent).toBe("false");
});

test("sending a message appends user message, calls mutation, and scrolls", async () => {
  render(<PlanChat initialMessage={initialMessage} query={query} />);

  const scroller = getChatBody();
  scroller.scrollTo = jest.fn();
  setScroll(scroller, {
    scrollHeight: 1000,
    clientHeight: 500,
    scrollTop: 500,
  });

  await act(async () => {
    fireEvent.click(screen.getByTestId("send-btn"));
  });

  expect(screen.getByTestId("msg-1").textContent).toBe(
    "message:user:User says hi",
  );

  expect(mockSendChatMessage).toHaveBeenCalledWith({
    conversationId: "conv-123",
    type: "chat",
    prompt: "User says hi",
    query,
  });

  expect(scroller.scrollTo).toHaveBeenCalledWith({
    top: scroller.scrollHeight,
    behavior: "smooth",
  });
});

test("subscription payload appends AI message and scrolls when at bottom", async () => {
  // 1) Start with NO data so the effect doesn't run yet
  mockSubscriptionData = null;

  const { rerender } = render(
    <PlanChat initialMessage={initialMessage} query={query} />,
  );

  // 2) Now stub scroll and geometry
  const scroller = getChatBody();
  scroller.scrollTo = jest.fn();
  setScroll(scroller, {
    scrollHeight: 1000,
    clientHeight: 500,
    scrollTop: 500, // at bottom
  });

  // 3) Provide subscription data and rerender so the effect fires now
  mockSubscriptionData = { message: "AI reply" };
  rerender(<PlanChat initialMessage={initialMessage} query={query} />);

  // allow effects to flush
  await act(async () => {});

  expect(screen.getByTestId("msg-1").textContent).toBe("message:ai:AI reply");
  expect(scroller.scrollTo).toHaveBeenCalledWith({
    top: scroller.scrollHeight,
    behavior: "smooth",
  });
});

test("hook-level mutation error appends an error message", () => {
  mockSendHookError = new Error("GraphQL error: boom!");

  render(<PlanChat initialMessage={initialMessage} query={query} />);

  expect(screen.getByTestId("msg-1").textContent).toBe(
    "error:ai:GraphQL error: boom!",
  );
});

test("hook-level subscription error appends an error and duplicates are avoided", () => {
  mockSendHookError = new Error("GraphQL error: boom!");
  const { rerender } = render(
    <PlanChat initialMessage={initialMessage} query={query} />,
  );
  expect(screen.getByTestId("msg-1").textContent).toBe(
    "error:ai:GraphQL error: boom!",
  );

  mockSendHookError = undefined;
  mockSubscriptionHookError = new Error("sub exploded");
  rerender(<PlanChat initialMessage={initialMessage} query={`${query}-2`} />);

  const transcript = screen.getByTestId("transcript");
  const rows = transcript.querySelectorAll("[data-testid^='msg-']");
  expect(rows[rows.length - 1].textContent).toBe("error:ai:sub exploded");

  rerender(<PlanChat initialMessage={initialMessage} query={`${query}-3`} />);

  const rows2 = transcript.querySelectorAll("[data-testid^='msg-']");
  expect(rows2.length).toBe(rows.length);
});

test("scroll button shows when scrolled away from bottom; hides when near bottom", async () => {
  render(<PlanChat initialMessage={initialMessage} query={query} />);

  const scroller = getChatBody();
  scroller.scrollTo = jest.fn();

  setScroll(scroller, {
    scrollHeight: 1000,
    clientHeight: 500,
    scrollTop: 100,
  });
  fireEvent.scroll(scroller);

  await act(async () => {
    await new Promise((r) => setTimeout(r, 0));
  });

  expect(screen.getByTestId("scroll-button-visible").textContent).toBe("true");

  setScroll(scroller, {
    scrollHeight: 1000,
    clientHeight: 500,
    scrollTop: 450,
  });
  fireEvent.scroll(scroller);

  await act(async () => {
    await new Promise((r) => setTimeout(r, 0));
  });

  expect(screen.getByTestId("scroll-button-visible").textContent).toBe("false");
});

test("ResizeObserver triggers auto-scroll when near bottom", async () => {
  render(<PlanChat initialMessage={initialMessage} query={query} />);

  const scroller = getChatBody();
  scroller.scrollTo = jest.fn();

  // Start near bottom
  setScroll(scroller, { scrollHeight: 800, clientHeight: 700, scrollTop: 120 });

  for (const ro of global.ResizeObserver.instances) ro.__trigger();
  await act(async () => {});

  expect(scroller.scrollTo).toHaveBeenCalledWith({
    top: scroller.scrollHeight,
    behavior: "smooth",
  });
});
