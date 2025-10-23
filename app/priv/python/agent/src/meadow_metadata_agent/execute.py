import asyncio
import json
from claude_agent_sdk import create_sdk_mcp_server, ClaudeAgentOptions, ClaudeSDKClient, AgentDefinition
from .prompts import (agent_prompt, proposer_prompt, system_prompt)
from .tools import (
    fetch_iiif_image_tool
)

async def query_claude(prompt, context_json, mcp_url, iiif_server_url, graphql_auth_token):
    context_data = json.loads(context_json) if context_json else {}
    enhanced_prompt = agent_prompt(prompt, context_data)

    # Build MCP server config with optional auth headers
    # Use HTTP type since Postman shows it works over HTTP POST
    meadow_server_config = {
        "type": "http",
        "url": mcp_url,
        "headers": {
            "Authorization": f"Bearer {graphql_auth_token}"
        } if graphql_auth_token else {}
    }
    print(f"Meadow MCP server config: {meadow_server_config}")

    client_options = ClaudeAgentOptions(
        mcp_servers={
            "meadow": meadow_server_config,
            "image_fetcher": create_sdk_mcp_server(
                name="metadata",
                version="1.0.0",
                tools=[fetch_iiif_image_tool]
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
            print(f"MESSAGE: {message}")
            if hasattr(message, 'content'):
                for block in message.content:
                    if hasattr(block, 'text'):
                        # Claude's text responses - don't store, just log
                        print(f"CLAUDE: {block.text}")
                    elif hasattr(block, 'tool_use_id'):
                        # Tool execution results - extract and immediately log
                        if isinstance(block.content, list) and len(block.content) > 0:
                            tool_text = block.content[0].get('text', str(block.content))
                            tool_output = f"🔧 Tool Result: {tool_text}"
                        else:
                            tool_output = f"🔧 Tool Result: {block.content}"

                        print(f"TOOL OUTPUT: {tool_output}")  # Log immediately

                    elif hasattr(block, 'name'):  # Tool use block
                        tool_args = getattr(block, 'input', {})
                        tool_call = f"🛠️  Using tool '{block.name}' with args: {tool_args}"
                        print(f"TOOL CALL: {tool_call}")  # Log immediately

            elif hasattr(message, 'result'):
                # Final result from ResultMessage - this is what we return
                if message.result:
                    final_result = message.result
                    print(f"FINAL: {final_result}")

        # Return just the final result content
        return final_result or "No result generated"

print("MetadataAgent Python tools initialized successfully")