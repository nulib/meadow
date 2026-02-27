import { agentPrompt, proposerPrompt, systemPrompt } from "./prompts.js";
import { query } from "@anthropic-ai/claude-agent-sdk";
import debug from "debug";

const log = debug("metadata-agent:execute");
const logMessage = debug("metadata-agent:all-messages");
const logVerbose = debug("metadata-agent:verbose");
const verboseTools = /^(mcp__meadow__|ReadMcpResource)/;
const uiLogPrefix = "[agent-log] ";
const maxPreviewLength = 800;
const maxStreamedLogs = 250;
const agentLogMutation = `
mutation SendAgentLog($planId: ID!, $message: String!, $level: String) {
  sendAgentLog(planId: $planId, message: $message, level: $level) {
    conversationId
  }
}
`;
let reportUiLog = () => {};

function emitAgentLog(message, level = "info") {
  if (!message) return;
  console.info(`${uiLogPrefix}${message}`);
  reportUiLog(message, level);
}

function preview(value, maxLength = maxPreviewLength) {
  let text = "";

  if (typeof value === "string") {
    text = value;
  } else {
    try {
      text = JSON.stringify(value);
    } catch (_error) {
      text = String(value);
    }
  }

  return text.length > maxLength ? `${text.slice(0, maxLength)}...` : text;
}

function logToolResults(message) {
  const blocks = message?.message?.content;
  if (!Array.isArray(blocks)) return;

  for (const block of blocks) {
    const isToolResult =
      block?.type === "tool_result" ||
      (Object.prototype.hasOwnProperty.call(block || {}, "tool_use_id") &&
        Object.prototype.hasOwnProperty.call(block || {}, "content"));

    if (isToolResult) {
      emitAgentLog(`tool_result: ${preview(block.content)}`);
    }
  }
}

export async function queryClaude(
  model,
  prompt,
  context,
  mcp_url,
  additional_headers,
) {
  const reporter = createLogReporter(context, mcp_url, additional_headers);
  reportUiLog = reporter.report;

  try {
    emitAgentLog("metadata-agent invocation started");
    emitAgentLog(`prompt_length: ${(prompt || "").length}`);
    emitAgentLog(`model: ${model}`);
    if (context?.plan_id) emitAgentLog(`plan_id: ${context.plan_id}`);

    if (context?.simple) {
      return await executeSimple(model, prompt, context);
    } else {
      return await executeAgent(
        model,
        prompt,
        context,
        mcp_url,
        additional_headers,
      );
    }
  } finally {
    emitAgentLog("metadata-agent invocation finished");
    await reporter.flush();
    reportUiLog = () => {};
  }
}

function logAssistantMessage(message) {
  for (const block of message.message.content) {
    if ("text" in block) {
      const text = block.text?.replace(/\s+/g, " ").trim();
      if (text) emitAgentLog(`assistant: ${preview(text)}`);
      log(block.text);
    } else if ("name" in block) {
      if (verboseTools.test(block.name) && block.input) {
        emitAgentLog(`tool_call: ${block.name} ${preview(block.input)}`);
        log(`Tool: ${block.name} ${JSON.stringify(block.input)}`);
      } else {
        emitAgentLog(`tool_call: ${block.name}`);
        log(`Tool: ${block.name}`);
      }
    }
  }
}

async function processAgentMessages(result) {
  emitAgentLog("waiting for model output");
  let finalResult = null;
  for await (const message of result) {
    logMessage("Message:", JSON.stringify(message, null, 2));
    if (message.type === "assistant" && message.message?.content) {
      logAssistantMessage(message);
    } else if (message.type === "user" && message.message?.content) {
      logToolResults(message);
    } else if (message.type === "result") {
      emitAgentLog(`completed: ${message.subtype}`);
      log(`Done: ${message.subtype}`);
      finalResult = message;
    }
  }
  return finalResult;
}

async function executeSimple(model, prompt, context) {
  emitAgentLog("mode: simple");
  const enhancedPrompt = `${prompt}\n\nContext: ${JSON.stringify(context, null, 2)}`;
  const result = await query({
    prompt: enhancedPrompt,
    model,
    systemPrompt:
      "You are a helpful assistant that responds to user queries. Do not use any tools.",
  });
  return await processAgentMessages(result);
}

async function executeAgent(
  model,
  prompt,
  contextData,
  mcp_url,
  additional_headers,
) {
  emitAgentLog("mode: agent");
  emitAgentLog("connecting to MCP tools");
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
      meadow: { type: "http", url: mcp_url, headers: additional_headers },
    },
    allowedTools,
    disallowedTools,
    agents: {
      plan_change_proposer: {
        prompt: proposerPrompt(),
        tools: allowedTools,
      },
    },
    systemPrompt: systemPrompt(),
  };
  logVerbose("Client options:", clientOptions);

  const enhancedPrompt = agentPrompt(prompt, contextData);
  logVerbose("Enhanced prompt:", enhancedPrompt);

  emitAgentLog("sending request to Claude");
  const result = await query({
    prompt: enhancedPrompt,
    options: clientOptions,
  });
  return await processAgentMessages(result);
}

function createLogReporter(context, mcpUrl, additionalHeaders) {
  const planId = context?.plan_id;
  const endpoint = graphQlUrlFromMcpUrl(mcpUrl);
  if (!planId || !endpoint) {
    return { report: () => {}, flush: async () => {} };
  }

  const headers = buildHeaders(additionalHeaders);
  let pending = Promise.resolve();
  let sentCount = 0;
  let sentTruncationNotice = false;

  const report = (message, level = "info") => {
    let safeMessage = preview(message, 2000);
    let safeLevel = level;

    if (sentCount >= maxStreamedLogs) {
      if (sentTruncationNotice) return;
      safeMessage = "Log stream truncated";
      safeLevel = "warning";
      sentTruncationNotice = true;
    } else {
      sentCount += 1;
    }

    pending = pending
      .then(() =>
        postAgentLog(endpoint, headers, planId, safeMessage, safeLevel),
      )
      .catch((error) => {
        console.warn("Failed to publish agent log:", error?.message || error);
        logVerbose("Failed to publish agent log", error);
      });
  };

  return {
    report,
    flush: async () => {
      try {
        await pending;
      } catch (_error) {
        // No-op
      }
    },
  };
}

function graphQlUrlFromMcpUrl(mcpUrl) {
  if (!mcpUrl) return null;
  try {
    const url = new URL(mcpUrl);
    url.pathname = "/api/graphql";
    url.search = "";
    return url.toString();
  } catch (_error) {
    return null;
  }
}

function buildHeaders(additionalHeaders) {
  const headers = { "Content-Type": "application/json" };
  for (const [name, value] of Object.entries(additionalHeaders || {})) {
    if (!name || value == null || value === "") continue;
    headers[name] = value;
  }
  return headers;
}

async function postAgentLog(endpoint, headers, planId, message, level) {
  const body = JSON.stringify({
    query: agentLogMutation,
    variables: { planId, message, level },
  });

  const response = await fetch(endpoint, {
    method: "POST",
    headers,
    body,
  });

  if (!response.ok) {
    throw new Error(`Failed to publish agent log: ${response.status}`);
  }

  let payload;
  try {
    payload = await response.json();
  } catch (_error) {
    throw new Error("Failed to parse sendAgentLog response");
  }

  if (Array.isArray(payload?.errors) && payload.errors.length > 0) {
    const messages = payload.errors
      .map((error) => error?.message)
      .filter(Boolean)
      .join("; ");
    throw new Error(messages || "sendAgentLog returned GraphQL errors");
  }

  if (!payload?.data?.sendAgentLog) {
    throw new Error("sendAgentLog returned no data");
  }
}
