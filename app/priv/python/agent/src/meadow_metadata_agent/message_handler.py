import json

class FallbackEncoder(json.JSONEncoder):
    def default(self, obj):
        try:
            return super().default(obj)
        except TypeError:
            return {
                'content_type': obj.__class__.__name__,
                'content': obj.__dict__
            }

def emit_message(message):
    if hasattr(message, 'usage'):
        emit(
            "usage",
            {"tokens": message.usage, "cost": getattr(message, "total_cost_usd", None)},
        )
        
    if hasattr(message, 'content'):
        for block in message.content:
            emit_content(block)
    elif hasattr(message, 'result'):
        if message.result:
            emit('final_result', message.result)
    else: # Fallback for other message types
        emit('raw_message', message)
            
def emit_content(block):
    if hasattr(block, 'text'):
        emit('text', block.text)
    elif hasattr(block, 'tool_use_id'):
        if isinstance(block.content, list) and len(block.content) > 0:
            tool_text = block.content[0].get('text', str(block.content))
        else:
            tool_text = block.content
        emit('tool_result', tool_text)

    elif hasattr(block, 'name'):  # Tool use block
        emit('tool_call', {
            'tool_name': block.name,
            'tool_args': getattr(block, 'input', {})
        })

def emit(message_type, message):
    output = {
        'type': message_type,
        'message': message
    }
    print(json.dumps(output, cls=FallbackEncoder))