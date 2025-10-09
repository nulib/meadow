// useChatResponse.test.jsx
const React = require("react");
const { act, renderHook, waitFor } = require("@testing-library/react");
const {
  ApolloClient,
  InMemoryCache,
  ApolloProvider,
} = require("@apollo/client");
const { MockSubscriptionLink } = require("@apollo/client/testing");

const { useChatResponse } = require("./useChatResponse");

function makeClientWithMockLink(mockLink) {
  return new ApolloClient({
    link: mockLink,
    cache: new InMemoryCache(),
  });
}

describe("useChatResponse (JS)", () => {
  test("starts loading, then returns first subscription payload", async () => {
    const link = new MockSubscriptionLink();
    const client = makeClientWithMockLink(link);

    const wrapper = ({ children }) => (
      <ApolloProvider client={client}>{children}</ApolloProvider>
    );

    const { result } = renderHook(() => useChatResponse("conv-123"), {
      wrapper,
    });

    expect(result.current.loading).toBe(true);
    expect(result.current.data).toBeUndefined();

    act(() => {
      link.simulateResult({
        result: {
          data: {
            chatResponse: {
              conversationId: "conv-123",
              message: "hello there",
            },
          },
        },
      });
    });

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
      expect(result.current.data).toEqual({
        conversationId: "conv-123",
        message: "hello there",
      });
      expect(result.current.error).toBeUndefined();
    });
  });

  test("emits subsequent updates", async () => {
    const link = new MockSubscriptionLink();
    const client = makeClientWithMockLink(link);
    const wrapper = ({ children }) => (
      <ApolloProvider client={client}>{children}</ApolloProvider>
    );

    const { result } = renderHook(() => useChatResponse("conv-123"), {
      wrapper,
    });

    act(() => {
      link.simulateResult({
        result: {
          data: {
            chatResponse: { conversationId: "conv-123", message: "first" },
          },
        },
      });
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        conversationId: "conv-123",
        message: "first",
      });
    });

    act(() => {
      link.simulateResult({
        result: {
          data: {
            chatResponse: { conversationId: "conv-123", message: "second" },
          },
        },
      });
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        conversationId: "conv-123",
        message: "second",
      });
    });
  });

  test("surfaces subscription errors via `error`", async () => {
    const link = new MockSubscriptionLink();
    const client = makeClientWithMockLink(link);
    const wrapper = ({ children }) => (
      <ApolloProvider client={client}>{children}</ApolloProvider>
    );

    const { result } = renderHook(() => useChatResponse("conv-err"), {
      wrapper,
    });

    act(() => {
      link.simulateResult({ error: new Error("boom") });
    });

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
      expect(result.current.data).toBeUndefined();
      expect(result.current.error).toBeTruthy();
      expect(result.current.error.message).toMatch(/boom/);
    });
  });

  test("re-subscribes when conversationId changes", async () => {
    const link = new MockSubscriptionLink();
    const client = makeClientWithMockLink(link);
    const wrapper = ({ children }) => (
      <ApolloProvider client={client}>{children}</ApolloProvider>
    );

    const { result, rerender } = renderHook(({ id }) => useChatResponse(id), {
      initialProps: { id: "a" },
      wrapper,
    });

    act(() => {
      link.simulateResult({
        result: {
          data: { chatResponse: { conversationId: "a", message: "from A" } },
        },
      });
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        conversationId: "a",
        message: "from A",
      });
    });

    rerender({ id: "b" });

    act(() => {
      link.simulateResult({
        result: {
          data: { chatResponse: { conversationId: "b", message: "from B" } },
        },
      });
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        conversationId: "b",
        message: "from B",
      });
    });
  });
});
