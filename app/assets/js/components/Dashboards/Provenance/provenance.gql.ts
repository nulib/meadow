import { gql } from "@apollo/client/core";

/**
 * Cross-work AI activity feed for the admin provenance dashboard.
 * Backed by the top-level `aiActivities` query (Editor role), filterable
 * by work/file set/plan as well as activity type, use type and status.
 */
export const GET_AI_ACTIVITIES = gql`
  query GetAIActivities(
    $activityType: String
    $aiUseType: String
    $status: String
    $limit: Int
  ) {
    aiActivities(
      activityType: $activityType
      aiUseType: $aiUseType
      status: $status
      limit: $limit
    ) {
      id
      activityType
      aiUseType
      status
      model
      modelProvider
      workId
      costUsd
      startedAt
      completedAt
      insertedAt
    }
  }
`;

export const GET_AI_ACTIVITY = gql`
  query GetAIActivity($id: ID!) {
    aiActivity(id: $id) {
      id
      activityType
      aiUseType
      accessMode
      reversibility
      status
      error
      model
      modelProvider
      modelVersion
      promptVersion
      costUsd
      workId
      fileSetId
      planId
      startedAt
      completedAt
      sources {
        id
        itemType
        itemId
        collectionTitle
        holdingOrganization
        accessLink
        restricted
      }
      targets {
        id
        targetType
        fieldPath
        operation
        origin
        status
        proposedValue
        events {
          id
          eventType
          actor
          occurredAt
          outcome
          notes
          agentLinks {
            id
            role
            agent {
              id
              agentType
              name
              version
            }
          }
        }
      }
    }
  }
`;
