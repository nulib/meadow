import React, { Component } from "react";
import { useEffect } from "react";
import { ReactiveList, ReactiveBase } from "@appbaseio/reactivesearch";
import axios from "axios";

const ElasticSearch = require("elasticsearch");

var protocol = location.protocol;
var slashes = protocol.concat("//");
var host = slashes.concat(window.location.hostname);

const ELASTICSEARCH_PROXY_ENDPOINT = `${host}/elasticsearch`;
const INDEX_NAME = "meadow";

const client = new ElasticSearch.Client({
  host: ELASTICSEARCH_PROXY_ENDPOINT
});

client.ping(
  {
    requestTimeout: 30000
  },
  function(error) {
    if (error) {
      console.error("Elasticsearch cluster is down!");
    } else {
      console.log("Everything is ok");
    }
  }
);

client
  .search({
    q: "hey",
    index: INDEX_NAME
  })
  .then(
    function(body) {
      console.log("Query string example");
      console.log(body.hits.hits);
    },
    function(error) {
      console.trace(error.message);
    }
  );

async function ElasticSearchClient(body) {
  try {
    let response = await client.search({ index: INDEX_NAME, body: body });
    console.log("ESClient query");
    console.log(response.hits.hits);
  } catch (err) {
    alert(err);
  }
}

function ElasticSearchRequestAxios(query) {
  axios
    .get(`${ELASTICSEARCH_PROXY_ENDPOINT}/${INDEX_NAME}/_search`, {
      params: {
        source: query,
        source_content_type: "application/json"
      },
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json"
      }
    })
    .then(res => {
      console.log("Axios - get");
      console.log(res.data.hits.hits);
    });
}

const ElasticsearchExample = () => {
  useEffect(() => {
    ElasticSearchClient('{"query": {"match_all": {}}}');
    ElasticSearchRequestAxios('{"query": {"match_all": {}}}');
  });
  return (
    <>
      <h1>Example ReactiveSearch</h1>
      <ReactiveBase url={ELASTICSEARCH_PROXY_ENDPOINT} app={INDEX_NAME}>
        <ReactiveList
          dataField="title"
          componentId="SearchResult"
          renderItem={res => <div key={res._id}>{res._id}</div>}
        />
      </ReactiveBase>
    </>
  );
};

export default ElasticsearchExample;
