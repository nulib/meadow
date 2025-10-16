import gql from "graphql-tag";

export const CHAT_RESPONSE = gql`
  subscription ChatResponse($conversationId: ID!) {
    chatResponse(conversationId: $conversationId) {
      conversationId
      message
      type
      planId
    }
  }
`;

export const SEND_CHAT_MESSAGE = gql`
  mutation SendChatMessage(
    $conversationId: ID!
    $type: String!
    $prompt: String!
    $query: String!
  ) {
    sendChatMessage(
      conversationId: $conversationId
      type: $type
      prompt: $prompt
      query: $query
    ) {
      conversationId
      type
      prompt
      query
    }
  }
`;
