import { GET_BATCHES } from "@js/components/Dashboards/dashboards.gql";

export const mockGetBatchesResults = [
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "f97d222b-3cf6-45ff-98c6-d09a3261964f",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Image"}},{"query_string":{"query":" id:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-08T15:27:13.396560Z",
    status: "ERROR",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
  {
    add:
      '{"administrative_metadata":{},"descriptive_metadata":{"alternate_title":["Alt title here"],"box_name":["Beta box"],"box_number":["14"],"contributor":[{"role":{"id":"asg","scheme":"marc_relator"},"term":"http://id.worldcat.org/fast/1204155"}],"keywords":["some key word","keyword2"]}}',
    delete: '{"genre":[{"term":"http://vocab.getty.edu/aat/300266117"}]}',
    error: null,
    id: "7b9fa4c5-fa97-46e8-8fd7-db0001dc76c3",
    nickname: "My Batch Job",
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Image"}},{"query_string":{"query":" id:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"description":["Description replacer"],"rights_statement":{"id":"http://rightsstatements.org/vocab/InC/1.0/","scheme":"rights_statement"}}}',
    started: "2020-12-08T17:24:49.278717Z",
    status: "COMPLETE",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 43,
  },
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "ABC-f97d222b-3cf6-45ff-98c6",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Image"}},{"query_string":{"query":" id:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-09T15:27:13.396560Z",
    status: "IN_PROGRESS",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
  {
    add: '{"administrative_metadata":{},"descriptive_metadata":{}}',
    delete: "{}",
    error: null,
    id: "ZYZ-f97d222b-3cf6-45ff-98c6",
    nickname: null,
    query:
      '{"query":{"bool":{"must":[{"match":{"model.name":"Image"}},{"query_string":{"query":" id:(aceee345-4fc9-4917-a499-7f9e0379231d OR 620cbd4f-7e44-45bc-aab9-0b0fb97ff2ea)"}}]}}}',
    replace:
      '{"administrative_metadata":{},"descriptive_metadata":{"title":"Yo Ima Batch Title"}}',
    started: "2020-12-09T15:27:13.396560Z",
    status: "QUEUED",
    type: "UPDATE",
    user: "aja0137",
    worksUpdated: 2,
  },
];

export const getBatchesMock = {
  request: {
    query: GET_BATCHES,
  },
  result: {
    data: {
      batches: mockGetBatchesResults,
    },
  },
};
