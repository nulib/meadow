import {
  GET_PROJECTS,
  GET_PROJECT,
  INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
  PROJECTS_SEARCH,
} from "./project.gql.js";

export const MOCK_PROJECT_TITLE = "Mock project title";
export const MOCK_PROJECT_TITLE_2 = "Second Mock project title";
export const MOCK_PROJECT_ID = "01DNFK4B8XASXNKBSAKQ6YVNF3";
export const MOCK_PROJECT_ID_2 = "01DNFK4B8XASXNKBSAKQ6YVNF32";

export const ingestSheetUpdatesMock = {
  request: {
    query: INGEST_SHEET_STATUS_UPDATES_FOR_PROJECT_SUBSCRIPTION,
    variables: {
      projectId: MOCK_PROJECT_ID,
    },
  },
  result: {
    data: {
      ingestSheetUpdatesForProject: {
        id: "01DNFK56MEN9H0C4CDBE7TECJT",
        name: "fffff",
        status: "VALID",
        updatedAt: "2019-10-07T16:16:57",
      },
    },
  },
};

export const getProjectMock = {
  request: {
    query: GET_PROJECT,
    variables: {
      projectId: MOCK_PROJECT_ID,
    },
  },
  result: {
    data: {
      project: {
        id: MOCK_PROJECT_ID,
        title: MOCK_PROJECT_TITLE,
        ingestSheets: [
          {
            id: "01DNFK56MEN9H0C4CDBE7TECJT",
            name: "fffff",
            status: "UPLOADED",
            updatedAt: "2019-10-07T16:16:57",
          },
          {
            id: "01DNFK9XNJ1FWE8GQGSTR3D1NE",
            name: "not a csv",
            status: "COMPLETED",
            updatedAt: "2019-10-07T16:16:57",
          },
        ],
        updatedAt: "2019-10-07T16:16:57",
      },
    },
  },
};

export const mockProjects = [
  {
    id: MOCK_PROJECT_ID,
    title: MOCK_PROJECT_TITLE,
    ingestSheets: [
      {
        id: "01DTYTYNJ161YWWVSMHMWZM4V2J7S1",
      },
      {
        id: "02DTYTYNJ161YWWVSMHMWZM4V2J7S12",
      },
    ],
    folder: "asdf-folder-name-123",
    updatedAt: "2020-02-29T02:02:02",
  },
  {
    id: MOCK_PROJECT_ID_2,
    title: MOCK_PROJECT_TITLE_2,
    ingestSheets: [
      {
        id: "01DTYTYNJ161YWWVSMHMWZM4V2J7S1",
      },
      {
        id: "02DTYTYNJ161YWWVSMHMWZM4V2J7S12",
      },
    ],
    folder: "asdf-folder-name-123",
    updatedAt: "2020-08-29T02:02:02",
  },
];

export const getProjectsMock = {
  request: {
    query: GET_PROJECTS,
  },
  result: {
    data: {
      projects: mockProjects,
    },
  },
};

export const projectsSearchMock = (searchTerm) => {
  return {
    request: {
      query: PROJECTS_SEARCH,
      variables: {
        query: searchTerm,
      },
    },
    result: {
      data: {
        projectsSearch: mockProjects,
      },
    },
  }
};
