import { agentPrompt, proposerPrompt, systemPrompt } from "./prompts.js";
import { query } from "@anthropic-ai/claude-agent-sdk";
import debug from "debug";

const log = debug("metadata-agent:execute");
const logMessage = debug("metadata-agent:all-messages");
const verboseTools = /^(mcp__meadow__|ReadMcpResource)/;

export async function queryClaude(model, prompt, context, mcp_url, additional_headers) {
  if (context?.simple) {
    return await executeSimple(model, prompt, context);
  } else {
    return await executeAgent(model, prompt, context, mcp_url, additional_headers);
  }
}

function logAssistantMessage(message) {
  for (const block of message.message.content) {
    if ("text" in block) {
      log(block.text);
    } else if ("name" in block) {
      if (verboseTools.test(block.name) && block.input) {
        log(`Tool: ${block.name} ${JSON.stringify(block.input)}`);
      } else {
        log(`Tool: ${block.name}`);
      }
    }
  }
}

async function processAgentMessages(result) {
  let finalResult = null;
  for await (const message of result) {
    logMessage("Message:", JSON.stringify(message, null, 2));
    if (message.type === "assistant" && message.message?.content) {
      logAssistantMessage(message);
    } else if (message.type === "result") {
      log(`Done: ${message.subtype}`);
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

async function executeAgent(model, prompt, contextData, mcp_url, additional_headers) {
  const allowedTools = [
    "mcp__meadow__authority_search",
    "mcp__meadow__get_code_list",
    "mcp__meadow__get_image",
    "mcp__meadow__get_plan_changes",
    "mcp__meadow__get_work",
    "mcp__meadow__propose_plan",
    "mcp__meadow__send_status_update",
    "mcp__meadow__update_plan_change",
  ];
  const disallowedTools = ["Bash", "Glob", "Grep", "Read", "WebFetch", "Write"];
  const clientOptions = {
    model,
    mcpServers: {
      "meadow": { type: "http", url: mcp_url, headers: additional_headers }
    },
    allowedTools,
    disallowedTools,
    agents: {
      "plan_change_proposer": {
        prompt: proposerPrompt(),
        tools: allowedTools,
      }
    },
    systemPrompt: systemPrompt()
  };

  const enhancedPrompt = agentPrompt(prompt, contextData);
  const result = await query({
    prompt: enhancedPrompt,
    options: clientOptions,
  });
  return await processAgentMessages(result);
}
