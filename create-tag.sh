#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${GITHUB_EVENT_PATH:-}" && -f "${GITHUB_EVENT_PATH}" ]]; then
  should_tag="$(
    python - <<'PY'
import json
import os

with open(os.environ["GITHUB_EVENT_PATH"], encoding="utf-8") as handle:
    event = json.load(handle)

pull_request = event.get("pull_request")
print("true" if pull_request and pull_request.get("merged") is True else "false")
PY
  )"

  if [[ "${should_tag}" != "true" ]]; then
    echo "Skipping tag creation because the event is not a merged pull request."
    exit 0
  fi
fi

version_file="${INPUT_VERSION_FILE}"

if [[ ! -f "${version_file}" ]]; then
  echo "Version file not found: ${version_file}" >&2
  exit 1
fi

version="$(
  VERSION_FILE="${version_file}" python - <<'PY'
import os
import re
import sys

with open(os.environ["VERSION_FILE"], encoding="utf-8") as handle:
    contents = handle.read()

match = re.search(r"\$plugin->version\s*=\s*['\"]?(\d+)['\"]?\s*;", contents)
if not match:
    sys.exit("Unable to find $plugin->version in version.php")

print(match.group(1))
PY
)"

tag="${INPUT_TAG_PREFIX}${version}"

echo "Resolved Moodle plugin version: ${version}"
echo "Target tag: ${tag}"

if git ls-remote --exit-code --tags origin "refs/tags/${tag}" >/dev/null 2>&1; then
  echo "Tag ${tag} already exists on origin. Nothing to do."
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git tag -a "${tag}" -m "Release ${tag}"

if [[ -n "${INPUT_GITHUB_TOKEN:-}" && -n "${GITHUB_REPOSITORY:-}" ]]; then
  git push "https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "refs/tags/${tag}"
else
  git push origin "refs/tags/${tag}"
fi
