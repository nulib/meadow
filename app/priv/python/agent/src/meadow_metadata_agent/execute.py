import asyncio
import json
from claude_agent_sdk import create_sdk_mcp_server, ClaudeAgentOptions, ClaudeSDKClient, AgentDefinition
from .tools import (
    fetch_iiif_image_tool
)

async def query_claude(prompt, context_json, mcp_url, iiif_server_url, graphql_auth_token):
    context_data = json.loads(context_json) if context_json else {}

    # Check if we have a plan_id in context - if so, instruct to use subagent
    plan_id = context_data.get("plan_id")

    if plan_id:
        # Build prompt for plan-based workflow
        enhanced_prompt = f"""
        Use the plan_change_proposer subagent to process the following plan:

        User query: {prompt}

        Plan ID: {plan_id}

        The plan_change_proposer subagent will:
        1. Retrieve all pending PlanChanges for plan {plan_id}
        2. Analyze each work's metadata
        3. Generate appropriate metadata changes based on your prompt
        4. Update each PlanChange with the proposed changes

        Context data: {json.dumps(context_data, indent=2)}

        Once the subagent completes, provide a summary of the changes proposed."""
    else:
        # Build a more explicit prompt that encourages tool usage
        enhanced_prompt = f"""
        Use the available tools to answer the following query:

        User query: {prompt}

        Context data: {json.dumps(context_data, indent=2) if context_data else "None"}

        Please use the appropriate tools to help answer this query. For example:
        - Before using the `call_graphql_endpoint` tool to query or update data, use it to discover the schema first.
        - The `fetch_iiif_image` tool can be used to quickly retrieve base64 encoded images by URL. Use the IIIF server URL: {iiif_server_url} and construct the full image URL by appending the file set ID followed by `/full/1000,1000/0/default.jpg`.

        Respond with both tool results and your analysis."""

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
            "mcp__meadow__update_plan_change",
            "mcp__image_fetcher__fetch_iiif_image"
        ],
        disallowed_tools=["Bash", "Grep", "Glob"],
        agents={
            "plan_change_proposer": AgentDefinition(
                description="Proposes metadata changes for works in a plan by analyzing work data and generating appropriate metadata updates",
                prompt="""You are a metadata change proposer for library catalog works.

Process ALL pending PlanChanges for a plan by following this loop:

LOOP:
1. Call get_plan_changes(plan_id: <plan_id>, status: "pending") to get pending changes
2. If no pending changes remain, STOP and return a summary
3. Take the FIRST pending PlanChange from the list
4. Query the work's current metadata using the graphql tool
5. Based on the plan's prompt and the work's data, generate appropriate metadata changes
6. Call update_plan_change with:
   - The PlanChange id
   - The proposed changes in the add/delete/replace fields
   - Set status to 'proposed'
7. Go back to step 1 (LOOP)

Continue looping until ALL PlanChanges have been processed (no pending changes remain).

Important:
- Always query work data - do not make assumptions
- Process changes one at a time
- Check for pending changes after each update to ensure nothing is missed
- Return a summary with the count of changes proposed when complete
""",
                tools=[
                    "mcp__meadow__graphql",
                    "mcp__meadow__get_plan_changes",
                    "mcp__meadow__update_plan_change"
                ]
            )
        },
        system_prompt="""
        Answer questions using only the tools available.

        When a plan_id is present in the context, delegate to the plan_change_proposer subagent
        to process all pending changes for that plan.

        Use the get_plan_changes tool to get a list of changes planned for a given plan UUID and work UUID.

        Do not look for information in the file system or local codebase.
        """)

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