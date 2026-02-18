import { agentPrompt, proposerPrompt, systemPrompt } from "./prompts.js";
import { query } from "@anthropic-ai/claude-agent-sdk";

export async function queryClaude(model, prompt, context, mcp_url, iiif_server_url, additional_headers) {
  if (context?.simple) {
    return await executeSimple(model, prompt, context);
  } else {
    return await executeAgent(model, prompt, context, mcp_url, iiif_server_url, additional_headers);
  }
}

async function processAgentMessages(result) {
  let finalResult = null;
  for await (const message of result) {
    if (message.type === "assistant" && message.message?.content) {
      for (const block of message.message.content) {
        if ("text" in block) {
          console.log(block.text);
        } else if ("name" in block) {
          console.log(`Tool: ${block.name}`);
        }
      }
    } else if (message.type === "result") {
      console.log(`Done: ${message.subtype}`);
      finalResult = message;
    }
  }
  return finalResult;
}

async function executeSimple(model, prompt, context) {
  const enhancedPrompt = `${prompt}\n\nContext: ${JSON.stringify(context, null, 2)}`;
  const result = await query({
    prompt: enhancedPrompt,
    model,
    systemPrompt: "You are a helpful assistant that responds to user queries. Do not use any tools.",
  });
  return await processAgentMessages(result);
}

async function executeAgent(model, prompt, contextData, mcp_url, iiif_server_url, additional_headers) {
  const clientOptions = {
    model,
    mcpServers: {
      "meadow": { type: "http", url: mcp_url, headers: additional_headers }
    },
    allowedTools: [
      "mcp__meadow__graphql",
      "mcp__meadow__get_plan_changes",
      "mcp__meadow__propose_plan",
      "mcp__meadow__update_plan_change",
      "mcp__meadow__send_status_update",
      "mcp__meadow__fetch_iiif_image",
    ],
    disallowedTools: ["Bash", "Grep", "Glob"],
    agents: {
      "plan_change_proposer": {
        prompt: proposerPrompt(),
        tools: [
          "mcp__meadow__graphql",
          "mcp__meadow__get_plan_changes",
          "mcp__meadow__propose_plan",
          "mcp__meadow__update_plan_change",
          "mcp__meadow__send_status_update",
          "mcp__meadow__fetch_iiif_image",
        ],
      }
    },
    systemPrompt: systemPrompt()
  };

  const enhancedPrompt = agentPrompt(prompt, contextData, iiif_server_url);
  const result = await query({
    prompt: enhancedPrompt,
    options: clientOptions,
  });
  return await processAgentMessages(result);
}
