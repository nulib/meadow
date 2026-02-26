import { queryClaude } from "./execute.js";
import debug from "debug";

const log = debug("metadata-agent:index");
export const handler = async (event) => {
  const { model, prompt, context, iiif_server_url, mcp_url, additional_headers } = event;
  log("Received event:", { model, prompt, context, iiif_server_url, mcp_url });
  const result = await queryClaude(model, prompt, context, mcp_url, iiif_server_url, additional_headers) || {};
  log("Query result:", result);
  return { statusCode: 200, body: JSON.stringify(result) };
};
