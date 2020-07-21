const protocol = location.protocol;
const slashes = protocol.concat("//");
const host = slashes.concat(window.location.hostname);
const port = window.location.port;

export const ELASTICSEARCH_PROXY_ENDPOINT = `${host}:${port}/elasticsearch`;
export const ELASTICSEARCH_INDEX_NAME = "meadow";

// ES Index fields we tell ReactiveSearch to search against
export const ELASTICSEARCH_FIELDS_TO_SEARCH = [
  "descriptiveMetadata.title",
  "descriptiveMetadata.description",
  "accessionNumber",
];
