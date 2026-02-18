import { queryClaude } from "./execute.js";
import fs from "node:fs";

export const handler = async (event) => {
  const { model, prompt, context, iiif_server_url, mcp_url, additional_headers } = event;
  const result = await queryClaude(model, prompt, context, mcp_url, iiif_server_url, additional_headers) || {};
  return { statusCode: 200, body: JSON.stringify(result) };
};
