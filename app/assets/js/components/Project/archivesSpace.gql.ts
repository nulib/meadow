import gql from "graphql-tag";

export const SEARCH_ARCHIVES_SPACE_RESOURCES = gql`
  query ArchivesSpaceResourceSearch($query: String!, $page: Int) {
    archivesSpaceResourceSearch(query: $query, page: $page) {
      results {
        uri
        title
        identifier
        importValidation {
          importable
          blockedReason
          blockedCount
          blockedSamples {
            uri
            title
            fileUri
          }
        }
      }
      totalHits
    }
  }
`;

export const LIST_ARCHIVES_SPACE_IMPORTS = gql`
  query ArchivesSpaceImports {
    archivesSpaceImports {
      id
      archivesSpaceUri
      findingAidUrl
      syncStatus
      workCount
      insertedAt
      collection {
        id
        title
      }
    }
  }
`;

export const START_ARCHIVES_SPACE_IMPORT_PREVIEW = gql`
  mutation StartArchivesSpaceImportPreview($resourceUri: String!) {
    archivesSpaceStartImportPreview(resourceUri: $resourceUri) {
      token
      status
    }
  }
`;

export const ARCHIVES_SPACE_IMPORT_PREVIEW_SUBSCRIPTION = gql`
  subscription ArchivesSpaceImportPreview($token: ID!) {
    archivesSpaceImportPreview(token: $token) {
      token
      status
      estimatedCost
      sampleCount
      totalCount
      error
      previews {
        workAccessionNumber
        title
        description
        thumbnail
        subjects {
          id
          label
        }
      }
    }
  }
`;

export const IMPORT_ARCHIVES_SPACE_RESOURCE = gql`
  mutation ImportArchivesSpaceResource(
    $resourceUri: String!
    $aiIngest: Boolean
  ) {
    importArchivesSpaceResource(
      resourceUri: $resourceUri
      aiIngest: $aiIngest
    ) {
      id
      title
      findingAidUrl
    }
  }
`;
