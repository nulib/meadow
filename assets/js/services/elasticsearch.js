const protocol = location.protocol;
const slashes = protocol.concat("//");
const host = slashes.concat(window.location.hostname);
const port = window.location.port;

export const ELASTICSEARCH_PROXY_ENDPOINT = `${host}:${port}/elasticsearch`;
export const ELASTICSEARCH_INDEX_NAME = "meadow";

const Elasticsearch = require("elasticsearch");
const client = new Elasticsearch.Client({
  host: ELASTICSEARCH_PROXY_ENDPOINT,
  //log: 'trace'
});

// ES Index fields we tell ReactiveSearch to search against
export const ELASTICSEARCH_FIELDS_TO_SEARCH = [
  "descriptiveMetadata.title",
  "descriptiveMetadata.description",
  "accessionNumber",
];

export const ELASTICSEARCH_AGGREGATION_FIELDS = {
  contributor: {
    terms: {
      field: "descriptiveMetadata.contributor.facet",
    },
  },
  creator: {
    terms: {
      field: "descriptiveMetadata.creator.facet",
    },
  },
  genre: {
    terms: {
      field: "descriptiveMetadata.genre.facet",
    },
  },
  language: {
    terms: {
      field: "descriptiveMetadata.language.facet",
    },
  },
  location: {
    terms: {
      field: "descriptiveMetadata.location.facet",
    },
  },
  stylePeriod: {
    terms: {
      field: "descriptiveMetadata.stylePeriod.facet",
    },
  },
  subject: {
    terms: {
      field: "descriptiveMetadata.subject.facet",
    },
  },
  technique: {
    terms: {
      field: "descriptiveMetadata.technique.facet",
    },
  },
};

/**
 * Create a text-only, label values object for an Elasticsearch aggregations result object
 * @param {object} aggregations Value returned from the Elasticsearch direct query
 * @returns {object}
 */
export function parseESAggregationResults(aggregations) {
  let returnObj = {};

  for (const property in aggregations) {
    returnObj[property] = [...aggregations[property].buckets];
  }

  return returnObj;
}

/**
 * Make a direct "search" request to Elasticsearch
 * @param {object} body
 * @returns {object} Pass through Elasticsearch response
 */
export async function elasticsearchDirectSearch(body) {
  try {
    let response = await client.search({
      index: ELASTICSEARCH_INDEX_NAME,
      body: body,
    });
    return response;
  } catch (err) {
    console.log("elasticsearchDirectSearch error", err);
    return Promise.resolve(null);
  }
}
