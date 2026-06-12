import { gql } from "@apollo/client";

export const GET_EVAL_QUERY_LIST = gql`
  query GetEvalQueryList {
    evalQueryList {
      id
      name
      description
      queryJson
      author
      insertedAt
    }
  }
`;

export const GET_DEFAULT_EVAL_QUERY = gql`
  query GetDefaultEvalQuery {
    defaultEvalQuery {
      id
      name
      description
      queryJson
    }
  }
`;

export const GET_EVAL_PROMPT_VERSIONS = gql`
  query GetEvalPromptVersions {
    evalPromptVersions {
      id
      name
      subjectPrompt
      descriptionPrompt
      systemPrompt
      userPromptTemplate
      parentVersionId
      author
      changeNotes
      archived
      insertedAt
    }
  }
`;

export const GET_EVAL_SETS = gql`
  query GetEvalSets {
    evalSets {
      id
      name
      description
      workCount
      author
      insertedAt
    }
  }
`;

export const GET_EVAL_RUNS = gql`
  query GetEvalRuns($limit: Int, $offset: Int) {
    evalRuns(limit: $limit, offset: $offset) {
      id
      name
      status
      trialsPerWork
      author
      startedAt
      completedAt
      insertedAt
      evalSet {
        id
        name
        workCount
      }
      promptVersion {
        id
        name
      }
      summary {
        total
        complete
        errored
        pending
        manualGood
        manualBad
        meanDescriptionJudgeScore
        meanSubjectsJudgeScore
      }
    }
  }
`;

export const GET_EVAL_RUN = gql`
  query GetEvalRun($id: ID!) {
    evalRun(id: $id) {
      id
      name
      status
      trialsPerWork
      author
      startedAt
      completedAt
      insertedAt
      error
      evalSet {
        id
        name
        workCount
        evalSetMembers {
          id
          workId
          accessionNumber
          groundTruth
        }
      }
      promptVersion {
        id
        name
        subjectPrompt
        descriptionPrompt
        systemPrompt
        userPromptTemplate
      }
      summary {
        total
        complete
        errored
        pending
        running
        manualGood
        manualBad
        meanDescriptionJudgeScore
        meanSubjectsJudgeScore
      }
      evalTrials {
        id
        workId
        trialIndex
        status
        descriptionJudgeScore
        subjectsJudgeScore
        judgeRationale
        manualScore
        manualNotes
        manualScoredBy
        manualScoredAt
        durationMs
        error
        agentOutput
        updatedAt
      }
    }
  }
`;

export const CREATE_EVAL_QUERY = gql`
  mutation CreateEvalQuery(
    $name: String!
    $description: String
    $queryJson: Json!
  ) {
    createEvalQuery(
      name: $name
      description: $description
      queryJson: $queryJson
    ) {
      id
      name
      description
      queryJson
      author
      insertedAt
    }
  }
`;

export const UPDATE_EVAL_QUERY = gql`
  mutation UpdateEvalQuery(
    $id: ID!
    $name: String
    $description: String
    $queryJson: Json
  ) {
    updateEvalQuery(
      id: $id
      name: $name
      description: $description
      queryJson: $queryJson
    ) {
      id
      name
      description
      queryJson
    }
  }
`;

export const DELETE_EVAL_QUERY = gql`
  mutation DeleteEvalQuery($id: ID!) {
    deleteEvalQuery(id: $id) {
      id
      name
    }
  }
`;

export const CREATE_EVAL_PROMPT_VERSION = gql`
  mutation CreateEvalPromptVersion(
    $name: String!
    $subjectPrompt: String!
    $descriptionPrompt: String!
    $parentVersionId: ID
    $changeNotes: String
  ) {
    createEvalPromptVersion(
      name: $name
      subjectPrompt: $subjectPrompt
      descriptionPrompt: $descriptionPrompt
      parentVersionId: $parentVersionId
      changeNotes: $changeNotes
    ) {
      id
      name
      archived
      insertedAt
    }
  }
`;

export const ARCHIVE_EVAL_PROMPT_VERSION = gql`
  mutation ArchiveEvalPromptVersion($id: ID!) {
    archiveEvalPromptVersion(id: $id) {
      id
      archived
    }
  }
`;

export const CREATE_EVAL_SET_FROM_WORK_IDS = gql`
  mutation CreateEvalSetFromWorkIds(
    $workIds: [ID!]!
    $name: String!
    $description: String
  ) {
    createEvalSetFromWorkIds(
      workIds: $workIds
      name: $name
      description: $description
    ) {
      id
      name
      workCount
      insertedAt
    }
  }
`;

export const CREATE_EVAL_SET = gql`
  mutation CreateEvalSet($queryId: ID!, $name: String!, $description: String) {
    createEvalSet(queryId: $queryId, name: $name, description: $description) {
      id
      name
      workCount
      insertedAt
    }
  }
`;

export const CREATE_EVAL_RUN = gql`
  mutation CreateEvalRun(
    $evalSetId: ID!
    $promptVersionId: ID!
    $name: String
    $trialsPerWork: Int
    $concurrency: Int
  ) {
    createEvalRun(
      evalSetId: $evalSetId
      promptVersionId: $promptVersionId
      name: $name
      trialsPerWork: $trialsPerWork
      concurrency: $concurrency
    ) {
      id
      name
      status
    }
  }
`;

export const CANCEL_EVAL_RUN = gql`
  mutation CancelEvalRun($id: ID!) {
    cancelEvalRun(id: $id) {
      id
      status
    }
  }
`;

export const SCORE_EVAL_TRIAL = gql`
  mutation ScoreEvalTrial($id: ID!, $score: EvalManualScore!, $notes: String) {
    scoreEvalTrial(id: $id, score: $score, notes: $notes) {
      id
      manualScore
      manualNotes
      manualScoredBy
      manualScoredAt
    }
  }
`;

export const CLEAR_EVAL_TRIAL_SCORE = gql`
  mutation ClearEvalTrialScore($id: ID!) {
    clearEvalTrialScore(id: $id) {
      id
      manualScore
      manualNotes
    }
  }
`;
