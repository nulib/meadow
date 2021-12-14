import { SET_COLLECTION_IMAGE, UPDATE_COLLECTION } from "./collection.gql.js";
import { GET_COLLECTIONS, GET_COLLECTION } from "./collection.gql.js";

export const MOCK_COLLECTION_ID = "7a6c7b35-41a6-465a-9be2-0587c6b39ae0";

export const collectionMock = {
  adminEmail: "admin@nu.com",
  description: "Collection description lorem ipsum",
  featured: false,
  findingAidUrl: "https://northwestern.edu",
  id: MOCK_COLLECTION_ID,
  keywords: ["yo", "foo", "bar", "work", "hey"],
  published: false,
  representativeWork: {
    id: "ABC123",
    representativeImage: "http://a-url-here.com/123",
  },
  title: "Great collection",
  totalWorks: 2,
  visibility: {
    id: "OPEN",
    label: "Public",
  },
};

export const getCollectionMock = {
  request: {
    query: GET_COLLECTION,
    variables: {
      id: MOCK_COLLECTION_ID,
    },
  },
  result: {
    data: {
      collection: collectionMock,
    },
  },
};

export const getCollectionsMock = {
  request: {
    query: GET_COLLECTIONS,
  },
  result: {
    data: {
      collections: [collectionMock],
    },
  },
};

export const setCollectionImageMock = {
  request: {
    query: SET_COLLECTION_IMAGE,
    variables: {
      collectionId: MOCK_COLLECTION_ID,
      workId: "1id-23343432",
    },
  },
  result: {
    data: {
      setCollectionImage: {
        id: MOCK_COLLECTION_ID,
        representativeWork: {
          id: "1id-23343432",
          representativeImage: "repImage1url.com",
        },
      },
    },
  },
};
