import {
  elasticSearchResponse,
  elasticSearchCountResponse,
} from "../../mock-data/elasticsearch-response";

export async function elasticsearchDirectSearch(body) {
  return new Promise((resolve, reject) => {
    process.nextTick(() => resolve(elasticSearchResponse));
  });
}
export async function elasticsearchDirectCount(body) {
  return new Promise((resolve, reject) => {
    process.nextTick(() => resolve(elasticSearchCountResponse));
  });
}

// const { Client } = require("@elastic/elasticsearch");
// const Mock = require("@elastic/elasticsearch-mock");

// const mock = new Mock();
// const client = new Client({
//   node: "http://localhost:9200",
//   Connection: mock.getConnection(),
// });

// mock.add(
//   {
//     method: "GET",
//     path: "/",
//   },
//   () => {
//     return { status: "ok" };
//   }
// );

// client.info(console.log);
