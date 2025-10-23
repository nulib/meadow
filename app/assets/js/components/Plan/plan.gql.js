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

export const PLAN_CHANGES = gql`
  subscription ($planId: ID!) {
    planChangesUpdated(planId: $planId) {
      planId
      planChange {
        status
        add
        replace
        delete
      }
    }
  }
`;

export const GET_PLAN = gql`
  query plan($id: ID!) {
    plan(id: $id) {
      id
      prompt
      query
      status
    }
  }
`;

export const GET_PLAN_CHANGES = gql`
  query planChanges($planId: ID!) {
    planChanges(planId: $planId) {
      id
      status
      add
      delete
      replace
    }
  }
`;
