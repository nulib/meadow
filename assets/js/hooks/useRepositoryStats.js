import React from "react";
import {
  elasticsearchDirectCount,
  elasticsearchDirectSearch,
} from "@js/services/elasticsearch";

/**
 * Elasticsearch queries
 */
const matchImage = {
  match: {
    "model.name.keyword": "Image",
  },
};

function query(matchItemsArray = []) {
  return {
    query: {
      bool: {
        must: [
          {
            match: {
              "model.application": "Meadow",
            },
          },
          ...matchItemsArray,
        ],
      },
    },
  };
}

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

function getVisbilityData(data = []) {
  const visibilityLabels = {
    authenticated: "Institution",
    open: "Public",
    restricted: "Private",
  };

  return data.map((obj) => {
    const publishedBucket = obj.published.buckets.find(
      (bucket) => bucket.key_as_string === "true"
    );
    const unpublishedBucket = obj.published.buckets.find(
      (bucket) => bucket.key_as_string === "false"
    );

    return {
      name: visibilityLabels[obj.key.toLowerCase()],
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
    worksPublished: 0,
  });

  const collectionsQuery = elasticsearchDirectCount(
    query([
      {
        match: {
          "model.name.keyword": "Collection",
        },
      },
    ])
  );
  const worksQuery = elasticsearchDirectCount(query([matchImage]));
  const worksPublishedQuery = elasticsearchDirectCount(
    query([
      matchImage,
      {
        match: {
          published: true,
        },
      },
    ])
  );
  // NOTE: This only returns projects which contain a work
  const projectsQuery = elasticsearchDirectSearch({
    ...query([matchImage]),
    size: 0,
    aggs: {
      projects: {
        terms: {
          field: "project.id",
        },
      },
    },
  });
  const visibilityQuery = elasticsearchDirectSearch({
    ...query([matchImage]),
    size: 0,
    aggs: {
      visibilities: {
        terms: {
          field: "visibility.id",
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
    ...query([matchImage]),
    size: 0,
    aggs: {
      works_created_by_week: {
        date_histogram: {
          field: "createDate",
          interval: "week",
        },
      },
    },
  });
  // This grabs max 3 Collections from works updated in past quarter
  const collectionsRecentlyUpdated = elasticsearchDirectSearch({
    ...query([matchImage]),
    size: 0,
    aggs: {
      works_recently_updated: {
        date_histogram: {
          field: "modifiedDate",
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

  React.useEffect(() => {
    const promises = [
      collectionsQuery,
      worksQuery,
      worksPublishedQuery,
      projectsQuery,
      visibilityQuery,
      worksCreatedByWeek,
      collectionsRecentlyUpdated,
    ];

    async function fn() {
      const resultArray = await Promise.all(promises);

      setStats({
        collections: resultArray[0].count,
        works: resultArray[1].count,
        worksPublished: resultArray[2].count,
        projects: getProjectsCount(
          resultArray[3].aggregations.projects.buckets
        ),
        visibility: getVisbilityData(
          resultArray[4].aggregations.visibilities.buckets
        ),
        worksCreatedByWeek: getWorksCreatedByWeek(
          resultArray[5].aggregations.works_created_by_week.buckets
        ),
        collectionsRecentlyUpdated: getRecentCollections(
          resultArray[6].aggregations.works_recently_updated.buckets
        ),
      });
    }
    fn();
  }, []);

  return { stats };
}
