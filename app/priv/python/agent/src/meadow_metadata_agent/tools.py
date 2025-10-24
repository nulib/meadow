# TOOLS

import base64
import requests
from claude_agent_sdk import tool
from typing import Any
from urllib import parse

def make_fetch_iiif_image_tool(additional_headers = {}):
    @tool("fetch_iiif_image", "Fetch an image from an IIIF image information URI (ending with 'info.json')", {
        "base_url": str
    })
    async def fetch_iiif_image_tool(args: dict[str, Any]) -> dict[str, Any]:
        base_url = args.get("base_url") if isinstance(args, dict) else args
        print(f"Fetching IIIF image from: {base_url}")
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
        print(f"Base64 preview: {encoded_image[:30]}...")

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
