import { extractQueryParts } from "@js/services/reactive-search";

describe("reactive-search.js service module", () => {
  describe("Elasticsearch query parser", () => {
    const query = {
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
                              "Dewey, Melvil, 1851-1931 (Voice actor)",
                              "Lovelace, Ada King, Countess of, 1815-1852 (Storyteller)",
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
                            "descriptiveMetadata.genre.displayFacet": [
                              "genre painters",
                            ],
                          },
                        },
                      ],
                    },
                  },
                  {
                    query_string: {
                      query: "explicabo",
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
                            "model.name": "Work",
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

    it("should return ", () => {
      const response = extractQueryParts(query);
      expect(response.search).toEqual("explicabo");

      const contributors =
        response.terms["descriptiveMetadata.contributor.displayFacet"];

      expect(contributors).toHaveLength(2);
      expect(contributors[0]).toEqual("Dewey, Melvil, 1851-1931 (Voice actor)");

      const genre = response.terms["descriptiveMetadata.genre.displayFacet"];
      expect(genre[0]).toEqual("genre painters");
    });
  });
});
