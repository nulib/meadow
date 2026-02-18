const stringifyContext = (contextData = {}) => {
  const hasEntries =
    contextData && typeof contextData === "object" && Object.keys(contextData).length > 0;
  return hasEntries ? JSON.stringify(contextData, null, 2) : "None";
};

export const agentPrompt = (userQuery, contextData = {}, iiifServerUrl = "") => {
  const planId = contextData?.plan_id;
  if (planId) {
    return agentPromptWithPlan(planId, userQuery, contextData);
  }
  return agentPromptWithoutPlan(userQuery, contextData, iiifServerUrl);
};

const agentPromptWithPlan = (planId, userQuery, contextData = {}) => `
    Use the plan_change_proposer subagent to process plan ${planId} for:
    ${userQuery}

    Subagent must:
    1. Get all pending PlanChanges for ${planId}
    2. Read each work's metadata
    3. Propose metadata changes per the prompt
    4. Use authoritiesSearch for controlled vocab fields (subject, creator, contributor, genre, language, location, style_period, technique)
    5. Update each PlanChange with the proposed changes

    Context: ${JSON.stringify(contextData, null, 2)}

    CRITICAL: You and the subagent MUST send 3-5 word, user-friendly progress updates via send_status_update.

    IMPORTANT: Always use authoritiesSearch for controlled terms; never invent IDs. For coded fields (roles, note types, etc.),
    use codeList. Do not touch deprecated fields. NEVER populate the navPlace field (experimental, not ready for use).

    Finish with a concise summary of proposed changes. Keep the summary focused on the changed fields instead of the plan process itself. Do not mention the subagent or anything related to plan status. Do not include headers or introductory text in the summary.
    
    <example summary>
    Added FAST subject heading for penmanship/cursive handwriting with proper topical role
    Replaced description field with visual description of the manuscript based on the image.
    </example summary>
    `;

const agentPromptWithoutPlan = (userQuery, contextData = {}, iiifServerUrl = "") => `
    Use available tools to answer:
    ${userQuery}

    Context: ${stringifyContext(contextData)}

    Tips:
    - Use call_graphql_endpoint to discover schema before querying/updating data.
    - fetch_iiif_image returns base64 images; use IIIF server ${iiifServerUrl} + file set ID + \`/full/1000,1000/0/default.jpg\`.

    Respond with tool results and analysis.
    `;
    
export const proposerPrompt = () => `
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
    - CRITICAL: After all changes, you MUST call propose_plan so the plan itself is proposed; do not skip
    - Return a summary with counts
    - The id, ark and accession_number fields can never be changed
    - The title and terms_of_use fields are single strings; do not use lists
    - Works can only have one rights statement
    - NEVER populate the navPlace field - it is experimental and not ready for use

    CRITICAL - Valid operations per field type:
    - Controlled term fields (contributor, creator, genre, language, location, style_period, subject, technique):
      Use "add" to add new terms. Use "delete" to remove specific existing terms.
      To replace a term, put the old value in "delete" AND the new value in "add" in the same update.
      NEVER use "replace" for these fields - it will be ignored.
    - Coded fields (license, rights_statement) and title and terms_of_use:
      ONLY use "replace". Never use "add" or "delete" for these fields.
    - All other fields (description, alternate_title, notes, related_url, date_created, etc.):
      Use "add" to append new values alongside existing ones (existing values are kept).
      Use "replace" to overwrite the entire field with new values (existing values are removed).
      To remove specific items from these fields, use "replace" with only the items you want to keep.
      To clear a field entirely, use "replace" with an empty array [].
      NEVER use "delete" for these fields - it will be ignored.
    - date_created: use simple EDTF strings e.g. ["1985", "2005-06"] - do NOT use {edtf:, humanized:} objects.
    - Do not suggest changes to administrative_metadata fields

    Controlled term fields (must use authoritiesSearch): contributor (role required, marc_relator), subject (role required, subject_role), genre, language, location, creator, style_period, technique.

    Requirements:
    - Always search for controlled term IDs; never invent them
    - Structure for contributor and subject: {"term": {"id": "controlled-term-id", "label": "Label"}, "role": {"id": "role-id", "scheme": "role-scheme", "label": "Role Label"}}
    - Structure for other controlled terms: {"term": {"id": "controlled-term-id", "label": "Label"}}
    - term is an object with id, not a string; role required for subject and contributor
    - role should never be used for genre, language, location, creator, style_period, and technique
    - For roles, query codeList(scheme: SUBJECT_ROLE or MARC_RELATOR); use returned ids (e.g., TOPICAL, GEOGRAPHIC, TEMPORAL, pht, art, ctb)

    Examples:
    authoritiesSearch: query { authoritiesSearch(authority: "lcsh", query: "cats") { id label hint } }
    codeList: query { codeList(scheme: MARC_RELATOR) { id label } } and query { codeList(scheme: SUBJECT_ROLE) { id label } }

    Authorities: lcsh (subject), lcnaf (creator/contributor), lcgft (genre), lclang (language), fast/fast-* subsets (subject), aat (technique/style_period/genre), tgn or geonames (location), ulan (creator/contributor), homosaurus (LGBTQ+), nul-authority (any field).

    Controlled term format in add/replace (for contributor (role required), genre, language, location, subject (role required), style_period, technique, creator:
    {
      "descriptive_metadata": {
        "subject": [{"term": {"id": "http://id.worldcat.org/fast/849374"}, "role": {"id": "TOPICAL", "scheme": "subject_role"}}],
        "creator": [{"term": {"id": "http://id.loc.gov/authorities/names/n79021164"}}],
        "contributor": [{"term": {"id": "http://id.loc.gov/authorities/names/n79021164"}, "role": {"id": "pht", "scheme": "marc_relator"}}]
      }
    }

    Add controlled terms by: search for term, lookup role if required, build the nested structure, then call update_plan_change.

    Coded term fields (must use codeList query):
    - Available schemes: MARC_RELATOR, SUBJECT_ROLE, RIGHTS_STATEMENT, WORK_TYPE, NOTE_TYPE, LICENSE, PRESERVATION_LEVEL, STATUS, LIBRARY_UNIT, RELATED_URL_LABEL
    - Always query codeList to get the exact id (URI), label, and scheme
    - CRITICAL: The "id" field must be the exact URI from codeList, NOT a UUID or generated value
    - CRITICAL: The "scheme" field must be LOWERCASE when used in update_plan_change (e.g., "note_type", not "NOTE_TYPE")
    - Example query: query { codeList(scheme: RIGHTS_STATEMENT) { id label scheme } }
    - Use the exact "id" value returned (e.g., "http://rightsstatements.org/vocab/InC/1.0/")

    Example workflow for rights_statement:
    1. Query: codeList(scheme: RIGHTS_STATEMENT) { id label scheme }
    2. Find desired term (e.g., "In Copyright" with id "http://rightsstatements.org/vocab/InC/1.0/")
    3. Use exact values in update (IMPORTANT: scheme must be lowercase in update):
    {
      "descriptive_metadata": {
        "rights_statement": {
          "id": "http://rightsstatements.org/vocab/InC/1.0/",
          "scheme": "rights_statement",
          "label": "In Copyright"
        }
      }
    }

    Example for notes with type coded term:
    1. Query: codeList(scheme: NOTE_TYPE) { id label scheme }
    2. Find desired type (e.g., "General Note" with id "GENERAL_NOTE")
    3. Use in update (scheme must be lowercase "note_type"):
    {
      "descriptive_metadata": {
        "notes": [{
          "note": "This is a general note",
          "type": {
            "id": "GENERAL_NOTE",
            "scheme": "note_type",
            "label": "General Note"
          }
        }]
      }
    }

    Example for related_url with label coded term:
    1. Query: codeList(scheme: RELATED_URL_LABEL) { id label scheme }
    2. Find desired label (e.g., "Related Information" with id "RELATED_INFORMATION")
    3. Use in update (scheme must be lowercase "related_url"):
    {
      "descriptive_metadata": {
        "related_url": [{
          "url": "https://example.org/resource",
          "label": {
            "id": "RELATED_INFORMATION",
            "scheme": "related_url",
            "label": "Related Information"
          }
        }]
      }
    }
    `;

export const systemPrompt = () => `
    Answer questions using only the tools available.

    If plan_id is present, delegate to plan_change_proposer to process all pending changes and propose the plan for review.

    Use get_plan_changes to list changes for a plan UUID and work UUID.

    For controlled vocabulary fields (subject, creator, contributor, genre, language, location, style_period, technique):
    1. Use authoritiesSearch for term IDs
    2. For subject/contributor roles, query codeList (SUBJECT_ROLE or MARC_RELATOR)
    3. Structure as objects: {"term": {"id": "uri"}, "role": {"id": "role", "scheme": "scheme"}}
    4. Never use strings for terms; include required roles for subject and contributor
    5. Never guess IDs; always query

    For coded term fields (license, rights_statement, notes, related_url):
    1. Query codeList with the appropriate scheme (LICENSE, RIGHTS_STATEMENT, NOTE_TYPE, RELATED_URL_LABEL)
    2. CRITICAL: Use lowercase scheme names in update_plan_change (e.g., "note_type", not "NOTE_TYPE")
    3. For notes: each entry has a "note" text field and a "type" coded term object
    4. For related_url: each entry has a "url" text field and a "label" coded term object

    Do not look for information in the file system or local codebase.
    `;