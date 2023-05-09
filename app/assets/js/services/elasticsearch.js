const protocol = location.protocol;
const slashes = protocol.concat("//");
const host = slashes.concat(window.location.hostname);
const port = window.location.port;

export const ELASTICSEARCH_PROXY_ENDPOINT = `${host}:${port}/_search`;
export const ELASTICSEARCH_INDEX_NAME = __ELASTICSEARCH_INDEX__;

const Elasticsearch = require("elasticsearch");

// The Elasticsearch Client v16.7.3 is deprecated and does not build
// correctly under esbuild unless you pass a custom Logger class in
// the `log` option. Upgrading to the new ES client should help.
// https://www.elastic.co/guide/en/elasticsearch/client/javascript-api/current/index.html
class NullLogger {
  constructor() {}

  debug() {}
  error() {}
  info() {}
  log() {}
  trace() {}
  warn() {}
}

const client = new Elasticsearch.Client({
  host: ELASTICSEARCH_PROXY_ENDPOINT,
  log: NullLogger,
});

export const ELASTICSEARCH_AGGREGATION_FIELDS = {
  contributor: {
    terms: {
      field: "descriptiveMetadata.contributor.facet",
      size: 1000,
    },
  },
  creator: {
    terms: {
      field: "descriptiveMetadata.creator.facet",
      size: 1000,
    },
  },
  genre: {
    terms: {
      field: "descriptiveMetadata.genre.facet",
      size: 1000,
    },
  },
  language: {
    terms: {
      field: "descriptiveMetadata.language.facet",
      size: 1000,
    },
  },
  location: {
    terms: {
      field: "descriptiveMetadata.location.facet",
      size: 1000,
    },
  },
  stylePeriod: {
    terms: {
      field: "descriptiveMetadata.stylePeriod.facet",
      size: 1000,
    },
  },
  subject: {
    terms: {
      field: "descriptiveMetadata.subject.facet",
      size: 1000,
    },
  },
  technique: {
    terms: {
      field: "descriptiveMetadata.technique.facet",
      size: 1000,
    },
  },
};

export const allWorksQuery = {
  track_total_hits: true,
  query: {
    bool: {
      must: [
        {
          match: {
            "model.name": "Work",
          },
        },
      ],
    },
  },
};

/**
 * Make a direct "count" request to Elasticsearch
 * @param {object} body
 * @returns {object} Pass through Elasticsearch response
 */
export async function elasticsearchDirectCount(body) {
  try {
    let response = await client.count({
      index: ELASTICSEARCH_INDEX_NAME,
      body: body,
    });
    return response;
  } catch (err) {
    console.log("elasticsearchDirectCount error", err);
    return Promise.resolve(null);
  }
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
