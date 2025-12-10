# TOOLS

import base64
import json
import requests
from claude_agent_sdk import tool
from typing import Any
from urllib import parse
from .message_handler import emit

@tool(
    name="send_status_update",
    description="Sends a status update message for a specific plan",
    input_schema={
        "type": "object",
        "properties": {
            "plan_id": {
                "type": "string",
                "description": "The unique identifier for the plan"
            },
            "message": {
                "type": "string",
                "description": "The status update message content to send"
            },
            "agent": {
                "type": "string",
                "description": "Identify yourself as an agent or a sub-agent"
            }
        },
        "required": ["plan_id", "message", "agent"]
    }
)
async def send_status_update_tool(args: dict[str, Any]) -> dict[str, Any]:
    plan_id = args.get("plan_id")
    message = args.get("message")
    agent = args.get("agent")
    if not message:
        return {
            "content": [{"type": "text", "text": "Error: message is required"}]
        }
    # Here you would implement the actual sending of the status update to the UI
    # For this example, we'll just log it
    payload = json.dumps({"plan_id": plan_id, "agent": agent, "message": message})
    emit("status_update", payload)
    return {
        "content": [{"type": "text", "text": f"Status update sent"}]
    }

def make_fetch_iiif_image_tool(additional_headers = {}):
    @tool("fetch_iiif_image", "Fetch an image from an IIIF image information URI (ending with 'info.json')", {
        "base_url": str
    })
    async def fetch_iiif_image_tool(args: dict[str, Any]) -> dict[str, Any]:
        base_url = args.get("base_url") if isinstance(args, dict) else args
        emit("debug", f"Fetching IIIF image from: {base_url}")
        if not base_url:
            return {
                "content": [{"type": "text", "text": "Error: base_url is required"}]
            }
        if not base_url.endswith("info.json"):
            return {
                "content": [{"type": "text", "text": "Error: base_url must be an image information ('info.json') URI"}]
            }
        try:
            image_url = parse.urljoin(base_url, 'full/!1024,1024/0/default.jpg')
            response = requests.get(image_url, headers=additional_headers, timeout=30)
            response.raise_for_status()
        except requests.RequestException as exc:
            return {
                "content": [{"type": "text", "text": f"Error fetching IIIF image: {exc}"}]
            }

        encoded_image = base64.b64encode(response.content).decode("utf-8")
        emit("debug", f"Base64 preview: {encoded_image[:30]}...")

        mime_type = response.headers.get("Content-Type", "image/jpeg")

        return {
            "content": [
                {
                    "type": "text",
                    "text": f"Fetched IIIF image for {base_url}"
                },
                {
                    "type": "image",
                    "mimeType": mime_type,
                    "data": encoded_image,
                },
            ]
        }

    return fetch_iiif_image_tool
