const protocol = location.protocol;
const slashes = protocol.concat("//");
const host = slashes.concat(window.location.hostname);

export const ELASTICSEARCH_PROXY_ENDPOINT = `${host}/elasticsearch`;
export const ELASTICSEARCH_INDEX_NAME = "meadow";
