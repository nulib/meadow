import gql from "graphql-tag";

export const GET_WORK = gql`
  query WorkQuery($id: ID!) {
    work(id: $id) {
      id
      accessionNumber
      fileSets {
        id
        accessionNumber
        metadata {
          description
        }
        work {
          id
        }
      }
      insertedAt
      descriptiveMetadata {
        title
      }
      updatedAt
      visibility
      workType
    }
  }
`;

export const GET_WORKS = gql`
  query WorksQuery {
    works {
      id
      accessionNumber
      fileSets {
        id
        accessionNumber
        metadata {
          description
        }
        work {
          id
        }
      }
      insertedAt
      descriptiveMetadata {
        title
      }
      updatedAt
      visibility
      workType
    }
  }
`;
