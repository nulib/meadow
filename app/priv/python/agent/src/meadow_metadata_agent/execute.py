import json
import sys
from claude_agent_sdk import create_sdk_mcp_server, ClaudeAgentOptions, ClaudeSDKClient, AgentDefinition, ResultMessage
from .prompts import (agent_prompt, proposer_prompt, system_prompt)
from .message_handler import emit, emit_message
from .tools import (make_fetch_iiif_image_tool)

async def query_claude(prompt, context_json, mcp_url, iiif_server_url, additional_headers={}):
    context_data = json.loads(context_json) if context_json else {}
    if context_data.get("simple"):
        return await execute_simple(prompt, context_data)
    else:
        return await execute_agent(prompt, context_data, mcp_url, iiif_server_url, additional_headers)
    
async def execute_simple(prompt, context_data):
    enhanced_prompt = f"{prompt}\n\nContext data: {json.dumps(context_data, indent=2) if context_data else 'None'}"
    client_options = ClaudeAgentOptions(
        system_prompt="You are a helpful assistant that responds to user queries. Do not use any tools."
    )

    return await execute_query(client_options, enhanced_prompt)

async def execute_agent(prompt, context_data, mcp_url, iiif_server_url, additional_headers={}):
    enhanced_prompt = agent_prompt(prompt, context_data)

    # Build MCP server config with optional auth headers
    # Use HTTP type since Postman shows it works over HTTP POST
    meadow_server_config = {
        "type": "http",
        "url": mcp_url,
        "headers": additional_headers
    }
    emit("debug", f"Meadow MCP server config: {meadow_server_config}")

    client_options = ClaudeAgentOptions(
        mcp_servers={
            "meadow": meadow_server_config,
            "image_fetcher": create_sdk_mcp_server(
                name="metadata",
                version="1.0.0",
                tools=[make_fetch_iiif_image_tool(additional_headers)]
            )
        },
        allowed_tools=[
            "mcp__meadow__graphql",
            "mcp__meadow__get_plan_changes",
            "mcp__meadow__propose_plan",
            "mcp__meadow__update_plan_change",
            "mcp__image_fetcher__fetch_iiif_image"
        ],
        disallowed_tools=["Bash", "Grep", "Glob"],
        agents={
            "plan_change_proposer": AgentDefinition(
                description="Proposes plan changes for works by analyzing work data and generating appropriate metadata updates",
                prompt=proposer_prompt(),
                tools=[
                    "mcp__meadow__graphql",
                    "mcp__meadow__get_plan_changes",
                    "mcp__meadow__propose_plan",
                    "mcp__meadow__update_plan_change",
                    "mcp__image_fetcher__fetch_iiif_image"
                ]
            )
        },
        system_prompt=system_prompt())
    
    return await execute_query(client_options, enhanced_prompt)

async def execute_query(client_options, prompt):
    async with ClaudeSDKClient(client_options) as client:
        await client.query(prompt)
        
        final_result = ""

        async for message in client.receive_response():
            emit_message(message)
            if isinstance(message, ResultMessage):
                final_result = message.result

        # Return just the final result content
        return final_result or "No result generated"

emit("info", "MetadataAgent Python tools initialized successfully")
