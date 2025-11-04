# AGENT_INTEGRATION

import asyncio
from meadow_metadata_agent.execute import query_claude

# Decode bytes to strings if needed (Pythonx passes Elixir binaries as bytes)
def ensure_string(value):
    if isinstance(value, bytes):
        return value.decode('utf-8')
    return value

# Convert all variables to strings
model_str = ensure_string(model)
prompt_str = ensure_string(prompt)
context_json_str = ensure_string(context_json)
mcp_url_str = ensure_string(mcp_url)
iiif_server_url_str = ensure_string(iiif_server_url)
additional_header_strs = {ensure_string(k): ensure_string(v) for k, v in additional_headers.items()}

asyncio.run(query_claude(model_str, prompt_str, context_json_str, mcp_url_str, iiif_server_url_str, additional_header_strs))
