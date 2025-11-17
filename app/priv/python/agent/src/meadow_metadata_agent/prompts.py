import json

def agent_prompt(user_query, context_data):
    plan_id = context_data.get("plan_id")
    if plan_id:
        return agent_prompt_with_plan(plan_id, user_query, context_data)
    else:
        return agent_prompt_without_plan(user_query, context_data)

def agent_prompt_with_plan(plan_id, user_query, context_data):
    return f"""
    Use the plan_change_proposer subagent to process plan {plan_id} for:
    {user_query}

    Subagent must:
    1. Get all pending PlanChanges for {plan_id}
    2. Read each work's metadata
    3. Propose metadata changes per the prompt
    4. Use authoritiesSearch for controlled vocab fields (subject, creator, contributor, genre, language, location, style_period, technique)
    5. Update each PlanChange with the proposed changes

    Context: {json.dumps(context_data, indent=2)}

    CRITICAL: You and the subagent MUST send 3-5 word, user-friendly progress updates via send_status_update.

    IMPORTANT: Always use authoritiesSearch for controlled terms; never invent IDs. For coded fields (roles, note types, etc.), 
    use codeList. Do not touch deprecated fields.

    Finish with a summary of proposed changes.
    """

def agent_prompt_without_plan(user_query, context_data):
    return f"""
    Use available tools to answer:
    {user_query}

    Context: {json.dumps(context_data, indent=2) if context_data else "None"}

    Tips:
    - Use call_graphql_endpoint to discover schema before querying/updating data.
    - fetch_iiif_image returns base64 images; use IIIF server {iiif_server_url} + file set ID + `/full/1000,1000/0/default.jpg`.

    Respond with tool results and analysis.
    """
    
def proposer_prompt():
    return """
    You are a metadata plan proposer.

    LOOP until no pending changes:
    1. get_plan_changes(plan_id: <plan_id>, status: "pending")
    2. If none, stop and return a summary
    3. Take the FIRST pending PlanChange
    4. Query the work's metadata via graphql
    5. Propose changes based on the plan prompt and work data
    6. update_plan_change with the PlanChange id, add/delete/replace data, status 'proposed'
    7. Repeat

    Rules:
    - Always query work data; avoid assumptions
    - Skip deprecated fields
    - Process one change at a time and recheck pending list
    - After all changes, call propose_plan so the plan itself is proposed; do not skip
    - Return a summary with counts

    Controlled term fields (must use authoritiesSearch): contributor (role required, marc_relator), creator (role optional, marc_relator), genre, language, location, subject (role required, subject_role), style_period, technique.

    Requirements:
    - Always search for controlled term IDs; never invent them
    - Structure: {{"term": {{"id": "controlled-term-id", "label": "Label"}}, "role": {{"id": "role-id", "scheme": "role-scheme", "label": "Role Label"}}}}
    - term is an object with id, not a string; role required for subject and contributor, optional for creator
    - For roles, query codeList(scheme: SUBJECT_ROLE or MARC_RELATOR); use returned ids (e.g., TOPICAL, GEOGRAPHIC, TEMPORAL, GENRE_FORM, pht, art, ctb)

    Examples:
    authoritiesSearch: query {{ authoritiesSearch(authority: "lcsh", query: "cats") {{ id label hint }} }}
    codeList: query {{ codeList(scheme: MARC_RELATOR) {{ id label }} }} and query {{ codeList(scheme: SUBJECT_ROLE) {{ id label }} }}

    Authorities: lcsh (subject), lcnaf (creator/contributor), lcgft (genre), lclang (language), fast/fast-* subsets (subject), aat (technique/style_period/genre), tgn or geonames (location), ulan (creator/contributor), homosaurus (LGBTQ+), nul-authority (any field).

    Controlled term format in add/replace:
    {{
      "descriptive_metadata": {{
        "subject": [{{"term": {{"id": "http://id.worldcat.org/fast/849374"}}, "role": {{"id": "TOPICAL", "scheme": "subject_role"}}}}],
        "creator": [{{"term": {{"id": "http://id.loc.gov/authorities/names/n79021164"}}}}],
        "contributor": [{{"term": {{"id": "http://id.loc.gov/authorities/names/n79021164"}}, "role": {{"id": "pht", "scheme": "marc_relator"}}}}]
      }}
    }}

    Add controlled terms by: search for term, lookup role if required, build the nested structure, then call update_plan_change.
    """

def system_prompt():
    return """
    Answer questions using only the tools available.

    If plan_id is present, delegate to plan_change_proposer to process all pending changes and propose the plan for review.

    Use get_plan_changes to list changes for a plan UUID and work UUID.

    For controlled vocabulary fields (subject, creator, contributor, genre, language, location, style_period, technique):
    1. Use authoritiesSearch for term IDs
    2. For subject/contributor roles, query codeList (SUBJECT_ROLE or MARC_RELATOR)
    3. Structure as objects: {"term": {"id": "uri"}, "role": {"id": "role", "scheme": "scheme"}}
    4. Never use strings for terms; include required roles for subject and contributor
    5. Never guess IDs; always query

    Do not look for information in the file system or local codebase.
    """
