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

export const PLAN_CHANGES_UPDATED = gql`
  subscription ($planId: ID!) {
    planChangesUpdated(planId: $planId) {
      planId
      action
      planChange {
        id
        status
        add
        replace
        delete
      }
    }
  }
`;

export const PLAN_UPDATED = gql`
  subscription ($planId: ID!) {
    planUpdated(planId: $planId) {
      id
      status
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

export const UPDATE_PLAN_STATUS = gql`
  mutation updatePlanStatus($id: ID!, $status: PlanStatus!) {
    updatePlanStatus(id: $id, status: $status) {
      id
      status
    }
  }
`;

export const UPDATE_PLAN_CHANGE_STATUS = gql`
  mutation updatePlanChangeStatus($id: ID!, $status: PlanStatus!) {
    updatePlanChangeStatus(id: $id, status: $status) {
      id
      status
    }
  }
`;

export const UPDATE_PROPOSED_PLAN_CHANGE_STATUSES = gql`
  mutation updateProposedPlanChangeStatuses(
    $planId: ID!
    $status: PlanStatus!
  ) {
    updateProposedPlanChangeStatuses(planId: $planId, status: $status) {
      planId
      status
    }
  }
`;

export const APPLY_PLAN = gql`
  mutation applyPlan($id: ID!) {
    applyPlan(id: $id) {
      id
      status
      completedAt
      error
    }
  }
`;
