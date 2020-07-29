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

export const ELASTICSEARCH_AGGS = {
  contributor: {
    terms: {
      field: "descriptiveMetadata.contributor.displayFacet",
    },
  },
  genre: {
    terms: {
      field: "descriptiveMetadata.genre.displayFacet",
    },
  },
  language: {
    terms: {
      field: "descriptiveMetadata.language.displayFacet",
    },
  },
  location: {
    terms: {
      field: "descriptiveMetadata.location.displayFacet",
    },
  },
  technique: {
    terms: {
      field: "descriptiveMetadata.technique.displayFacet",
    },
  },
};

/**
 * Create a text-only, label values object for an Elasticsearch aggregations result object
 * @param {object} aggregations Value returned from the Elasticsearch direct query
 * @returns {object}
 */
export function getAggregationTextValues(aggregations) {
  let parsedAggregations = {};

  for (const prop in aggregations) {
    let buckets = aggregations[prop].buckets;

    // Pull out the aggregation text value we'll want to display to the user
    parsedAggregations[prop] =
      buckets.length > 0 ? buckets.map((bucket) => bucket.key) : [];
  }

  return parsedAggregations;
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
