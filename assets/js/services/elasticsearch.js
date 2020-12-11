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
  "all_titles",
  "descriptiveMetadata.description",
  "full_text",
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

export const allImagesQuery = {
  query: {
    bool: {
      must: [
        {
          match: {
            "model.name": "Image",
          },
        },
      ],
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

const mySearchQuery = {
  query: {
    bool: {
      must: [
        {
          bool: {
            must: [
              {
                query_string: {
                  query: "yo",
                  fields: [
                    "all_titles^5",
                    "descriptiveMetadata.description^2",
                    "full_text",
                    "accessionNumber",
                  ],
                  default_operator: "or",
                },
              },
              {
                bool: {
                  must: [
                    {
                      match: {
                        "model.name": "Image",
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      ],
    },
  },
};

const myTermQuery = {
  query: {
    bool: {
      must: [
        {
          bool: {
            must: [
              {
                bool: {
                  should: [
                    {
                      terms: {
                        "descriptiveMetadata.contributor.displayFacet": [
                          "Dewey, Melvil, 1851-1931 (Marbler)",
                          "Dewey, Melvil, 1851-1931 (Voice actor)",
                        ],
                      },
                    },
                  ],
                },
              },
              {
                bool: {
                  should: [
                    {
                      terms: {
                        "descriptiveMetadata.creator.displayFacet": [
                          "Kahlo, Frida",
                        ],
                      },
                    },
                  ],
                },
              },
              {
                bool: {
                  must: [
                    {
                      match: {
                        "model.name": "Image",
                      },
                    },
                  ],
                },
              },
            ],
          },
        },
      ],
    },
  },
};

/**
 * Grab the search string and any facet values from an ElasticSearch query object
 * @param {Object} query An ElasticSearch query object
 * @returns { Object } Map object with keys "search" and "terms"
 */
export function extractQueryParts(query = {}) {
  const searchTermKey = "query_string";
  const facetTermsKey = "terms";

  let returnObj = {
    search: "",
    terms: {},
  };

  function findQueryParts(child) {
    if (typeof child !== "object" && child !== null) {
      return;
    }

    // Array value, loop through child objects
    if (Array.isArray(child)) {
      for (let arrayObj of child) {
        findQueryParts(arrayObj);
      }
    }

    // Grab search string
    if (child.hasOwnProperty(searchTermKey)) {
      returnObj.search = child[searchTermKey].query;
      return;
    }

    // Grab facet terms
    if (child.hasOwnProperty(facetTermsKey)) {
      returnObj.terms = { ...returnObj.terms, ...child[facetTermsKey] };
      return;
    }

    for (let property in child) {
      findQueryParts(child[property]);
    }
  }

  // Kick off recursive function
  findQueryParts(query);

  return returnObj;
}
