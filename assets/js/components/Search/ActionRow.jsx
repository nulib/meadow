import React from "react";
import PropTypes from "prop-types";
import { elasticsearchDirectSearch } from "../../services/elasticsearch";

export default function SearchActionRow({
  handleEditAllItems,
  numberOfResults,
  selectedItems = [],
}) {
  async function fireESQuery() {
    const body = {
      aggs: {
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
      },
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
                            "descriptiveMetadata.genre.displayFacet": [
                              "Rock music",
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
                            "descriptiveMetadata.license.label.keyword": [
                              "Attribution-NonCommercial-ShareAlike 4.0 International",
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
                            published: ["true"],
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

    console.log("fireESQuery() :>> ");
    let response = await elasticsearchDirectSearch(body);
    console.log("response :>> ", response);
  }

  return (
    <div className="field is-grouped">
      <p className="control">
        <button
          className="button is-light"
          onClick={handleEditAllItems}
          disabled={selectedItems.length > 0}
        >
          Edit All {numberOfResults} Items
        </button>
      </p>
      <p className="control">
        <button
          className="button is-light"
          disabled={selectedItems.length === 0}
        >
          View and Edit {selectedItems.length} Items
        </button>
      </p>
      <p className="control">
        <button className="button is-light">Deselect All (not wired up)</button>
      </p>
    </div>
  );
}

SearchActionRow.propTypes = {
  handleEditAllItems: PropTypes.func,
  numberOfResults: PropTypes.number,
  selectedItems: PropTypes.array,
};
