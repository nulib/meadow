#!/usr/bin/env bash
# .github/scripts/generate_release_notes.sh
#
# Generates human-readable release notes for a Meadow production release.
# Finds PRs merged since the last production tag, filters noise, calls
# Claude via Bedrock to summarize, then creates a GitHub Release.
#
# Required env vars:
#   GITHUB_TOKEN      - GitHub token with contents:write and pull-requests:read
#   MEADOW_VERSION    - Version being released (e.g. "1.2.3")
#   AWS_REGION        - AWS region for Bedrock (e.g. "us-east-1")
#
# Optional env vars:
#   GITHUB_REPOSITORY - Set automatically by GitHub Actions (owner/repo)
#   DRY_RUN           - Set to "true" to skip release creation and print output only
#
# Local testing (dry run):
#   export GITHUB_TOKEN=<your-pat>
#   export MEADOW_VERSION=<existing-tag-without-v, e.g. "1.2.3">
#   export AWS_REGION=us-east-1
#   export GITHUB_REPOSITORY=nulib/meadow
#   export DRY_RUN=true
#   bash .github/scripts/generate_release_notes.sh

set -euo pipefail

REPO="${GITHUB_REPOSITORY}"
CURRENT_TAG="v${MEADOW_VERSION}"
MODEL_ID="us.anthropic.claude-sonnet-4-6"
DRY_RUN="${DRY_RUN:-false}"

# Initialize so these are always set even if all PRs are filtered out
FILTERED_COUNT=0
PR_DETAIL_LIST=""
SUMMARY=""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "==> DRY RUN MODE — no GitHub Release will be created"
fi

# TEST_PR_LIST can be set to bypass GitHub API fetch entirely for testing
TEST_PR_LIST="${TEST_PR_LIST:-}"

echo "==> Generating release notes for ${CURRENT_TAG}"

if [[ -n "$TEST_PR_LIST" ]]; then
  # ---------------------------------------------------------------------------
  # TEST MODE: skip GitHub API and tag lookup, use provided PR list directly
  # ---------------------------------------------------------------------------
  echo "==> TEST MODE — using provided TEST_PR_LIST, skipping GitHub API"
  FILTERED_COUNT=$(echo "$TEST_PR_LIST" | grep -c "^-" || true)
  PR_DETAIL_LIST="$TEST_PR_LIST"

else
  # ---------------------------------------------------------------------------
  # 1. Find the previous production tag
  # ---------------------------------------------------------------------------
  echo "==> Finding previous tag..."

  PREVIOUS_TAG=$(git tag \
    --sort=-creatordate \
    --list "v*" \
    | grep -v "^${CURRENT_TAG}$" \
    | head -1)

  if [[ -z "$PREVIOUS_TAG" ]]; then
    echo "No previous tag found. Skipping release notes generation."
    exit 0
  fi

  echo "    Previous tag: ${PREVIOUS_TAG}"
  echo "    Current tag:  ${CURRENT_TAG}"

  # ---------------------------------------------------------------------------
  # 2. Fetch merged PRs between the two tags via GitHub API
  # ---------------------------------------------------------------------------
  echo "==> Fetching merged PRs between ${PREVIOUS_TAG} and ${CURRENT_TAG}..."

  # Get the date of the previous tag so we can filter PRs by merge date
  PREVIOUS_TAG_DATE=$(git log -1 --format="%cI" "${PREVIOUS_TAG}")
  echo "    Previous tag date: ${PREVIOUS_TAG_DATE}"

  PR_RESPONSE=$(curl -s \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO}/pulls?state=closed&base=deploy/staging&sort=updated&direction=desc&per_page=100&since=${PREVIOUS_TAG_DATE}")

  # Filter to PRs merged after the previous tag, extract title + labels + number
  PR_LIST=$(echo "$PR_RESPONSE" | jq -r --arg since "$PREVIOUS_TAG_DATE" '
    [
      .[] |
      select(
        .merged_at != null and
        .merged_at > $since
      ) |
      {
        number: .number,
        title: .title,
        labels: [.labels[].name],
        merged_at: .merged_at
      }
    ] | sort_by(.merged_at)
  ')

  PR_COUNT=$(echo "$PR_LIST" | jq 'length')
  echo "    Found ${PR_COUNT} merged PRs"

  if [[ "$PR_COUNT" -eq 0 ]]; then
    echo "No PRs found for this release. Creating release with minimal notes."
    SUMMARY="No pull requests were found for this release."
    PR_DETAIL_LIST=""
  else
    # -------------------------------------------------------------------------
    # 3. Filter out noise PRs
    # -------------------------------------------------------------------------
    echo "==> Filtering noise PRs..."

    FILTERED_PRS=$(echo "$PR_LIST" | jq -r '
      [
        .[] |
        select(
          (.title | ascii_downcase | test("^(dependabot|chore:|ci:|build:|bump version|increment version|deploy v|dependency rollup)") | not) and
          ((.labels | map(ascii_downcase) | any(. == "dependencies" or . == "chore" or . == "ci")) | not)
        )
      ]
    ')

    FILTERED_COUNT=$(echo "$FILTERED_PRS" | jq 'length')
    EXCLUDED_COUNT=$(( PR_COUNT - FILTERED_COUNT ))
    echo "    Kept ${FILTERED_COUNT} PRs, excluded ${EXCLUDED_COUNT} noise PRs"

    if [[ "$FILTERED_COUNT" -eq 0 ]]; then
      echo "All PRs were infrastructure/dependency updates. Creating release with minimal notes."
      SUMMARY="This release contains dependency updates and infrastructure improvements only."
      PR_DETAIL_LIST=""
    else
      PR_DETAIL_LIST=$(echo "$FILTERED_PRS" | jq -r '
        .[] | "- #\(.number): \(.title)"
      ')
    fi
  fi

fi # end TEST_PR_LIST bypass

# ---------------------------------------------------------------------------
# 4. Call Claude via Bedrock to generate plain-language release notes
# ---------------------------------------------------------------------------

if [[ -n "$PR_DETAIL_LIST" ]]; then
  echo "==> Calling Claude via Bedrock..."
  echo "    PRs to summarize:"
  echo "$PR_DETAIL_LIST" | sed 's/^/      /'

  PROMPT="You are writing release notes for Meadow, a digital collections management application used by library staff at Northwestern University Libraries.

Given the following list of pull request titles merged into this release, write concise, plain-language release notes suitable for non-technical library staff. Focus on what changed from the user's perspective — what they can now do, what was fixed, or what improved. Group related changes if it makes sense. Do not mention PR numbers, branch names, version numbers, or technical implementation details. Do not invent a title or header. Use plain prose or a short bullet list. Keep it under 200 words.

Pull requests in this release:
${PR_DETAIL_LIST}

Write only the release notes text, nothing else."

  REQUEST_PAYLOAD=$(jq -n \
    --arg prompt "$PROMPT" \
    '{
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 1024,
      messages: [
        {
          role: "user",
          content: $prompt
        }
      ]
    }')

  PAYLOAD_FILE=$(mktemp)
  echo "$REQUEST_PAYLOAD" > "$PAYLOAD_FILE"
  RESPONSE_FILE=$(mktemp)

  aws bedrock-runtime invoke-model \
    --region "${AWS_REGION}" \
    --model-id "${MODEL_ID}" \
    --content-type "application/json" \
    --accept "application/json" \
    --body "fileb://${PAYLOAD_FILE}" \
    "$RESPONSE_FILE"

  SUMMARY=$(jq -r '.content[0].text' "$RESPONSE_FILE")
  rm -f "$PAYLOAD_FILE" "$RESPONSE_FILE"

  echo "    Summary generated (${#SUMMARY} chars)"
fi

RELEASE_BODY="${SUMMARY}"

# ---------------------------------------------------------------------------
# 6. Create the GitHub Release (or print in dry run mode)
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" == "true" ]]; then
  echo ""
  echo "==> DRY RUN: Would create GitHub Release with the following:"
  echo ""
  echo "    Tag:  ${CURRENT_TAG}"
  echo "    Name: Meadow ${CURRENT_TAG}"
  echo ""
  echo "--- RELEASE BODY ---"
  echo "${RELEASE_BODY}"
  echo "--- END RELEASE BODY ---"
  echo ""
  echo "==> DRY RUN complete. No release was created."
  exit 0
fi

echo "==> Creating GitHub Release for ${CURRENT_TAG}..."

RELEASE_PAYLOAD=$(jq -n \
  --arg tag "$CURRENT_TAG" \
  --arg name "Meadow ${CURRENT_TAG}" \
  --arg body "$RELEASE_BODY" \
  '{
    tag_name: $tag,
    name: $name,
    body: $body,
    draft: false,
    prerelease: false
  }')

RELEASE_RESPONSE=$(curl -s \
  -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${REPO}/releases" \
  -d "$RELEASE_PAYLOAD")

RELEASE_URL=$(echo "$RELEASE_RESPONSE" | jq -r '.html_url')

if [[ "$RELEASE_URL" == "null" || -z "$RELEASE_URL" ]]; then
  echo "ERROR: Failed to create release. Response:"
  echo "$RELEASE_RESPONSE" | jq .
  exit 1
fi

echo "==> Release created successfully: ${RELEASE_URL}"