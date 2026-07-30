import { gql } from "@apollo/client/core";

/**
 * Per-work AI activity log, used by the Provenance tab to drill from a
 * field-level summary into the full proposed -> reviewed -> applied timeline.
 * The field-level summary itself comes from `work.aiProvenanceSummary` on the
 * GET_WORK query, so this is only fetched when the tab requests detail.
 */
export const GET_WORK_AI_ACTIVITIES = gql`
  query GetWorkAIActivities($workId: ID) {
    aiActivities(workId: $workId) {
      id
      activityType
      aiUseType
      status
      model
      modelProvider
      startedAt
      completedAt
      costUsd
      fileSetId
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
          itemIdentifier
          valueBefore
          valueAfter
        }
      }
    }
  }
`;
