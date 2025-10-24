import os
from claude_agent_sdk import create_sdk_mcp_server, McpServerConfig
from .tools import (
    fetch_iiif_image_tool
)

aws_bearer_token = os.getenv("AWS_BEARER_TOKEN_BEDROCK")
os.putenv("CLAUDE_CODE_USE_BEDROCK", "1")
aws_region = os.getenv("AWS_REGION", "us-east-1")
iiif_server_url = os.getenv("IIIF_SERVER_URL")

print(f"Configured for AWS Bedrock in region: {aws_region}")

image_fetcher = create_sdk_mcp_server(
    name="metadata",
    version="1.0.0",
    tools=[fetch_iiif_image_tool]
)