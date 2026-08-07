#!/usr/bin/env bash
set -euo pipefail

INPUT_TOKEN="${INPUT_TOKEN:-}"

log() {
  echo "::notice::$1"
}

fail() {
  echo "::error::$1"
  exit 1
}

set_output() {
  local name="$1"
  local value="$2"
  echo "${name}=${value}" >> "${GITHUB_OUTPUT}"
}

if [[ -n "${DEFAULT_BRANCH}" && "${GITHUB_REF_NAME}" != "${DEFAULT_BRANCH}" ]]; then
  log "Skipping tag creation: ref '${GITHUB_REF_NAME}' is not default branch '${DEFAULT_BRANCH}'"
  set_output version ""
  set_output tag ""
  set_output created "false"
  exit 0
fi

version_file="./version.php"
if [[ ! -f "${version_file}" ]]; then
  fail "version.php not found at '${version_file}'"
fi

# Extract $plugin->version = YYYYMMDDXX;
version="$(
  grep -E '\$plugin\s*->\s*version\s*=' "${version_file}" \
    | head -n 1 \
    | sed -E 's/.*\$plugin\s*->\s*version\s*=\s*([0-9]+).*/\1/'
)"

if [[ -z "${version}" || ! "${version}" =~ ^[0-9]+$ ]]; then
  fail "Could not parse \$plugin->version from '${version_file}'"
fi

tag="${version}"
set_output version "${version}"
set_output tag "${tag}"

log "Detected Moodle plugin version: ${version}"
log "Tag name: ${tag}"
log "Commit: ${GITHUB_SHA}"

# Check whether the tag already exists on the remote.
if git ls-remote --exit-code --tags "https://x-access-token:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "refs/tags/${tag}" >/dev/null 2>&1; then
  log "Tag '${tag}' already exists; skipping"
  set_output created "false"
  exit 0
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Ensure we tag the triggering commit even if checkout is shallow or detached.
git tag -a "${tag}" "${GITHUB_SHA}" -m "Moodle plugin version ${version}"

git push "https://x-access-token:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "refs/tags/${tag}"

log "Created and pushed tag '${tag}' on ${GITHUB_SHA}"
set_output created "true"
