import gql from "graphql-tag";

export const CREATE_PROJECT = gql`
  mutation CreateProject($projectTitle: String!) {
    createProject(title: $projectTitle) {
      id
      title
      folder
    }
  }
`;

export const DELETE_PROJECT = gql`
  mutation DeleteProject($projectId: ID!) {
    deleteProject(projectId: $projectId) {
      id
      title
    }
  }
`;

export const GET_PROJECT = gql`
  query GetProject($projectId: ID!) {
    project(id: $projectId) {
      id
      title
      ingestSheets {
        id
        name
      }
    }
  }
`;

export const GET_PROJECTS = gql`
  query GetProjects {
    projects {
      id
      title
      folder
      updated_at
      ingestSheets {
        id
      }
    }
  }
`;
