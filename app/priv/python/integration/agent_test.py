import asyncio
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions
global cli_path

async def test_claude_cli_installed():
    client_options = ClaudeAgentOptions(cli_path=cli_path) if 'cli_path' in globals() else ClaudeAgentOptions()
    client = ClaudeSDKClient(client_options)
    try:
        await client.connect()
        await client.disconnect()
        return {"initialized": True}
    except Exception as e:
        reason = str(e)
        return {"initialized": False, "exception": e.__class__.__name__, "reason": reason}
asyncio.run(test_claude_cli_installed())
