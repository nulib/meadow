import json
from claude_agent_sdk import create_sdk_mcp_server, ClaudeAgentOptions, ClaudeSDKClient, AgentDefinition
from .prompts import (agent_prompt, proposer_prompt, system_prompt)
from .message_handler import emit, emit_message
from .tools import (make_fetch_iiif_image_tool)

async def query_claude(prompt, context_json, mcp_url, iiif_server_url, additional_headers={}):
    context_data = json.loads(context_json) if context_json else {}
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

    async with ClaudeSDKClient(client_options) as client:
        await client.query(enhanced_prompt)

        final_result = ""

        async for message in client.receive_response():
            emit_message(message)

        # Return just the final result content
        return final_result or "No result generated"

emit("info", "MetadataAgent Python tools initialized successfully")
