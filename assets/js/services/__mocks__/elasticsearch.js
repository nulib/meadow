import { elasticSearchResponse } from "../../mock-data/elasticsearch-response";

export async function elasticsearchDirectSearch(body) {
  return new Promise((resolve, reject) => {
    process.nextTick(() => resolve(elasticSearchResponse));
  });
}
