# TOOLS

import base64
import requests
from claude_agent_sdk import tool
from typing import Any

@tool("fetch_iiif_image", "Fetch a IIIF image with a URL", {
    "url": str
})
async def fetch_iiif_image_tool(args: dict[str, Any]) -> dict[str, Any]:
    url = args.get("url") if isinstance(args, dict) else args
    if not url:
        return {"content": [{"type": "text", "text": "Error: url is required"}]}

    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
    except requests.RequestException as exc:
        return {
            "content": [{"type": "text", "text": f"Error fetching IIIF image: {exc}"}]
        }

    encoded_image = base64.b64encode(response.content).decode("utf-8")
    print(f"Base64 preview: {encoded_image[:30]}...")

    mime_type = response.headers.get("Content-Type", "image/jpeg")

    return {
        "content": [
            {
                "type": "text",
                "text": f"Fetched IIIF image for {url}"
            },
            {
                "type": "image",
                "mimeType": mime_type,
                "data": encoded_image,
            },
        ]
    }
