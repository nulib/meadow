import {
  ELASTICSEARCH_COLLECTION_INDEX,
  elasticsearchDirectCount,
  elasticsearchDirectSearch,
} from "@js/services/elasticsearch";

import { ELASTICSEARCH_FILE_SET_INDEX } from "../services/elasticsearch";
import React from "react";

/**
 * Data prep functions
 */
function getProjectsCount(buckets) {
  let count = 0;
  try {
    count = buckets.length;
  } catch (e) {
    console.error("Error getting Project Count", e);
  }
  return count;
}

function getRecentCollections(buckets) {
  try {
    const recentCollections = [];
    buckets.forEach((bucket) => {
      bucket.collection_ids.buckets.forEach((collectionBucket) => {
        recentCollections.push({
          id: collectionBucket.key,
        });
      });
    });
    return recentCollections;
  } catch (e) {
    console.error("Error prepping recent collections stats data", e);
    return [];
  }
}

function getWorksCreatedByWeek(buckets) {
  try {
    let workCount = 0;
    let worksByWeek = buckets.map((obj) => {
      workCount = workCount + obj.doc_count;
      return {
        timestamp: obj.key,
        works: workCount,
      };
    });
    return worksByWeek;
  } catch (error) {
    console.error("Error prepping works created by week", error);
    return [];
  }
}

function getFileSetsCreatedByWeek(buckets) {
  try {
    let fileSetCount = 0;
    let fileSetsByWeek = buckets.map((obj) => {
      fileSetCount = fileSetCount + obj.doc_count;
      return {
        timestamp: obj.key,
        fileSets: fileSetCount,
      };
    });
    return fileSetsByWeek;
  } catch (error) {
    console.error("Error prepping file sets created by week", error);
    return [];
  }
}

function getVisbilityData(data = []) {
  return data.map((obj) => {
    const publishedBucket = obj.published.buckets.find(
      (bucket) => bucket.key_as_string === "true",
    );
    const unpublishedBucket = obj.published.buckets.find(
      (bucket) => bucket.key_as_string === "false",
    );

    return {
      name: obj.key,
      works: obj.doc_count,
      published: publishedBucket ? publishedBucket.doc_count : 0,
      unpublished: unpublishedBucket ? unpublishedBucket.doc_count : 0,
    };
  });
}

/**
 * The Hook component
 */
export default function useRepositoryStats() {
  const [stats, setStats] = React.useState({
    collections: 0,
    works: 0,
    fileSets: 0,
    worksPublished: 0,
  });

  const collectionsQuery = elasticsearchDirectCount(
    {},
    ELASTICSEARCH_COLLECTION_INDEX,
  );
  const worksQuery = elasticsearchDirectCount({});
  const fileSetsQuery = elasticsearchDirectCount(
    {},
    ELASTICSEARCH_FILE_SET_INDEX,
  );
  const worksPublishedQuery = elasticsearchDirectCount({
    query: {
      match: {
        published: true,
      },
    },
  });
  // NOTE: This only returns projects which contain a work
  const projectsQuery = elasticsearchDirectSearch({
    size: 0,
    aggs: {
      projects: {
        terms: {
          field: "project.name",
        },
      },
    },
  });
  const visibilityQuery = elasticsearchDirectSearch({
    size: 0,
    aggs: {
      visibilities: {
        terms: {
          field: "visibility",
        },
        aggs: {
          published: {
            terms: {
              field: "published",
            },
          },
        },
      },
    },
  });
  const worksCreatedByWeek = elasticsearchDirectSearch({
    size: 0,
    aggs: {
      works_created_by_week: {
        date_histogram: {
          field: "create_date",
          interval: "week",
        },
      },
    },
  });
  // This grabs max 3 Collections from works updated in past quarter
  const collectionsRecentlyUpdated = elasticsearchDirectSearch({
    size: 0,
    aggs: {
      works_recently_updated: {
        date_histogram: {
          field: "modified_date",
          interval: "quarter",
        },
        aggs: {
          collection_ids: {
            // Ideally it'd be great to get Collection title here too, but can only
            // aggregate one field per terms according to ES docs
            // https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations-bucket-terms-aggregation.html
            terms: {
              field: "collection.id",
              size: 3,
            },
          },
        },
      },
    },
  });
  const fileSetsCreatedByWeek = elasticsearchDirectSearch(
    {
      size: 0,
      aggs: {
        file_sets_created_by_week: {
          date_histogram: {
            field: "create_date",
            interval: "week",
          },
        },
      },
    },
    ELASTICSEARCH_FILE_SET_INDEX,
  );

  React.useEffect(() => {
    const promises = [
      collectionsQuery,
      worksQuery,
      fileSetsQuery,
      worksPublishedQuery,
      projectsQuery,
      visibilityQuery,
      worksCreatedByWeek,
      collectionsRecentlyUpdated,
      fileSetsCreatedByWeek,
    ];

    async function fn() {
      const resultArray = await Promise.all(promises);

      setStats({
        collections: resultArray[0].count,
        works: resultArray[1].count,
        fileSets: resultArray[2].count,
        worksPublished: resultArray[3].count,
        ...(resultArray[4] && {
          projects: getProjectsCount(
            resultArray[4].aggregations.projects.buckets,
          ),
        }),
        ...(resultArray[5] && {
          visibility: getVisbilityData(
            resultArray[5].aggregations.visibilities.buckets,
          ),
        }),
        ...(resultArray[6] && {
          worksCreatedByWeek: getWorksCreatedByWeek(
            resultArray[6].aggregations.works_created_by_week.buckets,
          ),
        }),
        ...(resultArray[7] && {
          collectionsRecentlyUpdated: getRecentCollections(
            resultArray[7].aggregations.works_recently_updated.buckets,
          ),
        }),
        ...(resultArray[8] && {
          fileSetsCreatedByWeek: getFileSetsCreatedByWeek(
            resultArray[8].aggregations.file_sets_created_by_week.buckets,
          ),
        }),
      });
    }
    fn();
  }, []);

  return { stats };
}
