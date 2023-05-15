const protocol = location.protocol;
const slashes = protocol.concat("//");
const host = slashes.concat(window.location.hostname);
const port = window.location.port;

export const ELASTICSEARCH_PROXY_ENDPOINT = `${host}:${port}/_search`;
export const ELASTICSEARCH_WORK_INDEX = __ELASTICSEARCH_WORK_INDEX__;
export const ELASTICSEARCH_COLLECTION_INDEX =
  __ELASTICSEARCH_COLLECTION_INDEX__;
export const ELASTICSEARCH_FILE_SET_INDEX = __ELASTICSEARCH_FILE_SET_INDEX__;

const fetch = require("node-fetch");

export const ELASTICSEARCH_AGGREGATION_FIELDS = {
  contributor: {
    terms: {
      field: "contributor.facet",
      size: 1000,
    },
  },
  creator: {
    terms: {
      field: "creator.facet",
      size: 1000,
    },
  },
  genre: {
    terms: {
      field: "genre.facet",
      size: 1000,
    },
  },
  language: {
    terms: {
      field: "language.facet",
      size: 1000,
    },
  },
  location: {
    terms: {
      field: "location.facet",
      size: 1000,
    },
  },
  stylePeriod: {
    terms: {
      field: "style_period.facet",
      size: 1000,
    },
  },
  subject: {
    terms: {
      field: "subject.facet",
      size: 1000,
    },
  },
  technique: {
    terms: {
      field: "technique.facet",
      size: 1000,
    },
  },
};

export const allWorksQuery = {
  track_total_hits: true,
};

function elasticsearchUrl(leaf) {
  return [ELASTICSEARCH_PROXY_ENDPOINT, leaf].join("/");
}

/**
 * Make a direct "count" request to Elasticsearch
 * @param {object} body
 * @returns {object} Pass through Elasticsearch response
 */
export async function elasticsearchDirectCount(
  body,
  index = ELASTICSEARCH_WORK_INDEX,
) {
  try {
    let response = await fetch(elasticsearchUrl(`${index}/_count`), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    return await response.json();
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
export async function elasticsearchDirectSearch(
  body,
  index = ELASTICSEARCH_WORK_INDEX,
) {
  try {
    let response = await fetch(elasticsearchUrl(`${index}/_search`), {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    return await response.json();
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
