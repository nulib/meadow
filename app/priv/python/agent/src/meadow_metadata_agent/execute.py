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
        4. Use authoritiesSearch for all controlled vocabulary fields (subject, creator, contributor, genre, language, location, style_period, technique)
        5. Update each PlanChange with the proposed changes

        Context data: {json.dumps(context_data, indent=2)}

        IMPORTANT: For controlled vocabulary fields like subject headings, creator names, genres, etc.,
        the subagent MUST use the authoritiesSearch GraphQL query to find valid controlled term IDs.
        Never make up or guess term IDs for these fields.

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

CRITICAL - Controlled Term Fields:
The following fields REQUIRE controlled terms from external authorities and MUST use the authoritiesSearch GraphQL query:
- contributor (with REQUIRED role from marc_relator)
- creator (with optional role from marc_relator)
- genre
- language
- location
- subject (with REQUIRED role from subject_role)
- style_period
- technique

For these fields, you MUST:
1. Use the authoritiesSearch query to find valid controlled term IDs
2. Never make up or guess term IDs
3. The data structure MUST be (note that term is an OBJECT with id field):
   {
     "term": {"id": "controlled-term-id-from-search"},
     "role": {"id": "role-id", "scheme": "role-scheme"}
   }

IMPORTANT STRUCTURE NOTES:
- "term" MUST be an object with "id" field, NOT a bare string
- "role" is REQUIRED for subject and contributor fields
- "role" is optional for creator field

FINDING ROLE VALUES:
- For subject roles: Query codeList(scheme: SUBJECT_ROLE) to get valid role IDs
  Common values: "TOPICAL", "GEOGRAPHIC", "TEMPORAL", "GENRE_FORM"
- For contributor/creator roles: Query codeList(scheme: MARC_RELATOR) to get valid role IDs
  These are 3-letter codes like "pht" (photographer), "art" (artist), "ctb" (contributor)
- Always use the exact "id" value returned from the codeList query

Example authoritiesSearch query to find controlled term IDs:
query {
  authoritiesSearch(authority: "lcsh", query: "cats") {
    id
    label
    hint
  }
}

Example codeList query to get available role codes:
query {
  codeList(scheme: MARC_RELATOR) {
    id
    label
  }
}

query {
  codeList(scheme: SUBJECT_ROLE) {
    id
    label
  }
}

Available authorities (use appropriate one for the field type):
- "lcsh" - Library of Congress Subject Headings (for subject)
- "lcnaf" - Library of Congress Name Authority (for creator, contributor)
- "lcgft" - Library of Congress Genre/Form Terms (for genre)
- "lclang" - Library of Congress Languages (for language)
- "fast" - FAST terms (alternative for subjects)
- "fast-personal", "fast-corporate-name", "fast-geographic", "fast-topical", "fast-form" - specific FAST subsets
- "aat" - Getty AAT (for technique, style_period, genre)
- "tgn" - Getty TGN (for location)
- "ulan" - Getty ULAN (for creator, contributor)
- "geonames" - GeoNames (for location)
- "homosaurus" - Homosaurus LGBTQ+ vocabulary
- "nul-authority" - Northwestern local authority (for any field)

The controlled term format in add/replace operations:
{
  "descriptive_metadata": {
    "subject": [
      {"term": {"id": "http://id.worldcat.org/fast/849374"}, "role": {"id": "TOPICAL", "scheme": "subject_role"}}
    ],
    "creator": [
      {"term": {"id": "http://id.loc.gov/authorities/names/n79021164"}}
    ],
    "contributor": [
      {"term": {"id": "http://id.loc.gov/authorities/names/n79021164"}, "role": {"id": "pht", "scheme": "marc_relator"}}
    ]
  }
}

WORKFLOW FOR ADDING CONTROLLED TERMS:
1. First, use authoritiesSearch to find the controlled term ID (the "term" value)
2. If the field requires a role (subject, contributor), query codeList to get valid role IDs
3. Construct the entry with the correct nested structure:
   {"term": {"id": "found-term-id"}, "role": {"id": "found-role-id", "scheme": "appropriate-scheme"}}
4. Use update_plan_change to add the properly structured entry

When adding controlled terms, ALWAYS search first to get the correct IDs!
""",
                tools=[
                    "mcp__meadow__graphql",
                    "mcp__meadow__get_plan_changes",
                    "mcp__meadow__update_plan_change",
                    "mcp__image_fetcher__fetch_iiif_image"
                ]
            )
        },
        system_prompt="""
        Answer questions using only the tools available.

        When a plan_id is present in the context, delegate to the plan_change_proposer subagent
        to process all pending changes for that plan.

        Use the get_plan_changes tool to get a list of changes planned for a given plan UUID and work UUID.

        CRITICAL: When working with controlled vocabulary fields (subject, creator, contributor, genre,
        language, location, style_period, technique), you MUST:
        1. Use the authoritiesSearch GraphQL query to find valid controlled term IDs
        2. For fields requiring roles (subject, contributor), use codeList query to get valid role IDs:
           - codeList(scheme: SUBJECT_ROLE) for subject roles
           - codeList(scheme: MARC_RELATOR) for contributor/creator roles
        3. Structure the term correctly as an OBJECT: {"term": {"id": "uri"}, "role": {"id": "role", "scheme": "scheme"}}
        4. Never use bare strings for term values - they must be objects with "id" field
        5. Include required "role" field for subject and contributor fields

        Never make up or guess term IDs or role IDs - always query for them first.

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