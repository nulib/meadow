# AGENT_INTEGRATION

import asyncio
from meadow_metadata_agent.execute import query_claude

# Decode bytes to strings if needed (Pythonx passes Elixir binaries as bytes)
def ensure_string(value):
    if isinstance(value, bytes):
        return value.decode('utf-8')
    return value

# Convert all variables to strings
prompt_str = ensure_string(prompt)
context_json_str = ensure_string(context_json)
mcp_url_str = ensure_string(mcp_url)
iiif_server_url_str = ensure_string(iiif_server_url)
graphql_auth_token_str = ensure_string(graphql_auth_token)

asyncio.run(query_claude(prompt_str, context_json_str, mcp_url_str, iiif_server_url_str, graphql_auth_token_str))
