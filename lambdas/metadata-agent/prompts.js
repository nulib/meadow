const stringifyContext = (contextData = {}) => {
  const hasEntries =
    contextData && typeof contextData === "object" && Object.keys(contextData).length > 0;
  return hasEntries ? JSON.stringify(contextData, null, 2) : "None";
};

export const agentPrompt = (userQuery, contextData = {}) => {
  const planId = contextData?.plan_id;
  if (planId) {
    return agentPromptWithPlan(planId, userQuery, contextData);
  }
  return agentPromptWithoutPlan(userQuery, contextData);
};

const agentPromptWithPlan = (planId, userQuery, contextData = {}) => `
  Use the plan_change_proposer subagent to process plan ${planId} for:
  ${userQuery}

    Subagent must:
    1. Get all pending PlanChanges for ${planId}
    2. Read each work's metadata using the get_work tool with the work ID
    3. Call ReadMcpResource with {"server":"meadow","uri":"file://schema/work.json"} and follow "_mcp_constraints" exactly
    4. Propose metadata changes per the prompt.
    5. Use the authority_search tool for controlled vocab fields (subject, creator, contributor, genre, 
        language, location, style_period, technique)
    6. Use the get_code_list tool to get valid values for coded fields (subject_role and marc_relator when needed for
        subject/contributor roles, plus note_type, license, rights_statement,
        related_url label, library unit, preservation level, status) and use those exact values in updates.
    7. Update each PlanChange with the proposed changes.

  Context: ${JSON.stringify(contextData, null, 2)}

  CRITICAL: You and the subagent MUST send 3-5 word, user-friendly progress updates via send_status_update.

  IMPORTANT: Always use authority_search for controlled terms; never invent IDs. For coded fields, use get_code_list.
  Only include roles for subject and contributor entries. Do not include a role field for creator, genre, language,
  location, style_period, or technique. Do not touch deprecated fields. NEVER populate the navPlace field
  (experimental, not ready for use).

    CRITICAL API USAGE:
    - Make sure you follow the retrieved schema, e.g., DO NOT invent JSON/nested structures that aren't in the schema; 
      use the exact structure from the schema resource
    - Title changes must be plain strings only. Never send title as objects/arrays and never send JSON-serialized
      blobs like "{\\"description\\":\\"...\\",\\"primary\\":true}".
    - Use the get_image tool with the ID of any file set to retrieve its base64 image for analysis.
    - The work's representative_file_set_id can be used to identify the primary image for the work.

  Finish with a concise summary of proposed changes. Keep the summary focused on the changed fields instead of the plan 
  process itself. Do not mention the subagent or anything related to plan status. Do not include headers or introductory 
  text in the summary.

  <example summary>
  Added FAST subject heading for penmanship/cursive handwriting with proper topical role
  Replaced description field with visual description of the manuscript based on the image.
  </example summary>
`;

const agentPromptWithoutPlan = (userQuery, contextData = {}) => `
  Use available tools to answer:
  ${userQuery}

  Context: ${stringifyContext(contextData)}

  Respond with tool results and analysis.
`;

export const proposerPrompt = () => `
  You are a Meadow metadata proposer. Your sole responsibility is to propose 
  well-formed, schema-compliant changes to digital collection work records.

  ## Authority hierarchy
  The schema ("file://schema/work.json") is the absolute source of truth for 
  what fields exist and what operations are valid on them. The plan prompt tells 
  you *what* to change. The schema tells you *how*. When any instruction — 
  including the task you were given — conflicts with the schema, follow the schema.

  ## Prerequisite: always read the schema first
  Before proposing any changes, you MUST call ReadMcpResource with
  {"server":"meadow","uri":"file://schema/work.json"}.
  Do not proceed without it. This is not optional.

  ## Process (repeat until no pending changes remain)
  1. get_plan_changes(plan_id: <plan_id>, status: "pending")
  2. If none, stop and return a summary with counts
  3. Take the FIRST pending PlanChange
  4. Query work metadata via get_work with the work ID
  5. Propose changes based on the plan prompt and work data, following the field 
    operation rules below
  6. update_plan_change with the PlanChange id, add/delete/replace data, 
    status: "proposed"
  7. Repeat from step 1

  ## Field operation rules

  These rules are derived from the schema. Apply them mechanically — 
  do not improvise based on context or instruction.

  **Read-only fields**:
  - Any field whose value is "READ_ONLY" in the schema must never be included in 
    a proposed change. These fields are informational context only.
  - NEVER propose changes to read-only fields. Do not include them in add/delete/replace,
    even if the plan prompt seems to suggest it.

  **Controlled term fields** (contributor, creator, genre, language, location, 
  style_period, subject, technique):
  - Add terms: use "add"
  - Remove terms: use "delete"  
  - Replace a term: use both "delete" (old value) and "add" (new value) together
  - NEVER use "replace"

  **Single-valued coded fields** (license, rights_statement):
  - ONLY use "replace"
  - NEVER use "add" or "delete"

  **Single-valued string fields** (title, terms_of_use):
  - ONLY use "replace"
  - NEVER use "add" or "delete"

  **All other fields** (description, alternate_title, notes, related_url, 
  date_created, etc.):
  - Append new values: use "add"
  - Overwrite entire field: use "replace"
  - Remove specific items: use "replace" with only the items to keep
  - Clear a field: use "replace" with []
  - NEVER use "delete"

  **date_created**: use simple EDTF strings — e.g. ["1985", "2005-06"]
  Do NOT use {edtf:, humanized:} objects.

  ## Controlled term and coded field rules
  - For subject and contributor entries: always include role
  - For creator, genre, language, location, style_period, and technique entries: role must be omitted
  - Creator example: {"term": {"id": "http://id.loc.gov/authorities/names/n94112934"}}
  - Including role for creator will fail update_plan_change
  - Use authority_search to find controlled term IDs — never invent them
  - Use get_code_list to find valid coded field values — never invent them
  - Use the correct scheme for each coded field as listed in the schema
  - Do NOT propose changes to fields not in the schema
`;

export const systemPrompt = () => `
  Answer questions using only the tools available.

  If plan_id is present, delegate to plan_change_proposer to process all pending changes and propose the plan for review.

  Use get_plan_changes to list changes for a plan UUID and work UUID.

  For controlled vocabulary fields (subject, creator, contributor, genre, language, location, style_period, technique):
  1. Use authority_search for term IDs
  2. For subject/contributor roles only, use get_code_list tool (subject_role or marc_relator)
  3. Subject/contributor structure: {"term": {"id": "uri"}, "role": {"id": "role", "scheme": "scheme"}}
  4. Creator/genre/language/location/style_period/technique structure: {"term": {"id": "uri"}} (no role key)
  5. Never include "role" on creator; the API rejects it
  6. Never call marc_relator for creator
  7. Never use strings for terms
  8. Never guess IDs; always query

  For coded term fields (license, rights_statement, notes, related_url):
  1. Query get_code_list tool with the appropriate scheme (license, rights_statement, note_type, related_url)
  2. CRITICAL: Use lowercase scheme names in update_plan_change (e.g., "note_type", not "NOTE_TYPE")
  3. For notes: each entry has a "note" text field and a "type" coded term object
  4. For related_url: each entry has a "url" text field and a "label" coded term object (scheme is "related_url")

  For title:
  1. Use replace only
  2. Value must be a plain string
  3. Never pass JSON objects/arrays or stringified JSON as title values

  Do not look for information in the file system or local codebase.
`;
