// useSendChatMessage.test.jsx
const React = require("react");
const { renderHook, act, waitFor } = require("@testing-library/react");
const { MockedProvider } = require("@apollo/client/testing");

const { useSendChatMessage } = require("./useSendChatMessage");
import { SEND_CHAT_MESSAGE } from "@js/components/Plan/plan.gql";

function wrapperWithMocks(mocks) {
  return ({ children }) => (
    <MockedProvider mocks={mocks} addTypename={false}>
      {children}
    </MockedProvider>
  );
}

describe("useSendChatMessage", () => {
  const vars = {
    conversationId: "conv-123",
    type: "user",
    prompt: "Say hi",
    query: "hello",
  };

  test("returns data after a successful mutation", async () => {
    const mocks = [
      {
        request: {
          query: SEND_CHAT_MESSAGE,
          variables: vars,
        },
        result: {
          data: {
            sendChatMessage: {
              conversationId: vars.conversationId,
              type: vars.type,
              prompt: vars.prompt,
              query: vars.query,
            },
          },
        },
      },
    ];

    const { result } = renderHook(() => useSendChatMessage(), {
      wrapper: wrapperWithMocks(mocks),
    });

    // initial state
    expect(result.current.loading).toBe(false);
    expect(result.current.error).toBeUndefined();
    expect(result.current.data).toBeUndefined();

    // call mutate
    await act(async () => {
      await result.current.sendChatMessage(vars);
    });

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
      expect(result.current.error).toBeUndefined();
      expect(result.current.data).toEqual({
        sendChatMessage: {
          conversationId: "conv-123",
          type: "user",
          prompt: "Say hi",
          query: "hello",
        },
      });
    });
  });

  test("surfaces GraphQL errors", async () => {
    const mocks = [
      {
        request: { query: SEND_CHAT_MESSAGE, variables: vars },
        result: { errors: [new (require("graphql").GraphQLError)("boom")] },
      },
    ];

    const { result } = renderHook(() => useSendChatMessage(), {
      wrapper: ({ children }) => (
        <MockedProvider mocks={mocks} addTypename={false}>
          {children}
        </MockedProvider>
      ),
    });

    await act(async () => {
      try {
        await result.current.sendChatMessage({
          conversationId: "conv-123",
          type: "user",
          prompt: "Say hi",
          query: "hello",
        });
      } catch (_) {}
    });

    await waitFor(() => {
      expect(result.current.error).toBeTruthy();

      const err = result.current.error;
      const combined = [
        err.message,
        ...(err.graphQLErrors || []).map((e) => e?.message),
      ]
        .filter(Boolean)
        .join(" | ");

      expect(combined).toMatch(/boom/);
    });
  });

  test("handles multiple calls (updates data each time)", async () => {
    const mocks = [
      {
        request: {
          query: SEND_CHAT_MESSAGE,
          variables: vars,
        },
        result: {
          data: {
            sendChatMessage: {
              conversationId: "conv-123",
              type: "user",
              prompt: "Say hi",
              query: "hello",
            },
          },
        },
      },
      {
        request: {
          query: SEND_CHAT_MESSAGE,
          variables: vars,
        },
        result: {
          data: {
            sendChatMessage: {
              conversationId: "conv-123",
              type: "user",
              prompt: "Say hi (again)",
              query: "hello again",
            },
          },
        },
      },
    ];

    const { result } = renderHook(() => useSendChatMessage(), {
      wrapper: wrapperWithMocks(mocks),
    });

    await act(async () => {
      await result.current.sendChatMessage(vars);
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        sendChatMessage: {
          conversationId: "conv-123",
          type: "user",
          prompt: "Say hi",
          query: "hello",
        },
      });
    });

    await act(async () => {
      await result.current.sendChatMessage(vars);
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({
        sendChatMessage: {
          conversationId: "conv-123",
          type: "user",
          prompt: "Say hi (again)",
          query: "hello again",
        },
      });
    });
  });
});
