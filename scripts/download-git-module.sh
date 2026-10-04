#!/usr/bin/env bash
set -euo pipefail

command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required." >&2; exit 1; }

# Latest GitHub Release .modl from the Ignition Git module repository.
# Release URL: https://github.com/WhiskeyHouse/ignition-git-module/releases/latest
# (TheThoughtagen/ignition-git-module, previously linked in this stack, has no release assets.)
repo="${GIT_MODULE_RELEASE_REPO:-WhiskeyHouse/ignition-git-module}"
if [[ -n "${GIT_MODULE_VERSION:-}" ]]; then
  api_url="https://api.github.com/repos/${repo}/releases/tags/${GIT_MODULE_VERSION}"
else
  api_url="https://api.github.com/repos/${repo}/releases/latest"
fi

curl_auth=()
token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [[ -n "$token" ]]; then
  curl_auth=(--header "Authorization: Bearer ${token}")
fi

json="$(curl --fail --silent --show-error --location \
  --header "Accept: application/vnd.github+json" \
  "${curl_auth[@]}" \
  "$api_url")"

tag="$(printf '%s' "$json" | jq -r '.tag_name // empty')"
asset="$(printf '%s' "$json" | jq -r '
  (.assets // [])
  | map(select(.name | test("\\.modl$"; "i")))
  | sort_by(
      if (.name | test("unsigned"; "i")) then 0
      elif (.name | test("signed"; "i")) then 2
      else 1
      end
    )
  | last
  | select(.)
  | {name, browser_download_url}
')"
asset_name="$(printf '%s' "$asset" | jq -r '.name // empty')"
asset_url="$(printf '%s' "$asset" | jq -r '.browser_download_url // empty')"

if [[ -z "$tag" || -z "$asset_name" || -z "$asset_url" ]]; then
  echo "No Git module .modl found on ${api_url}" >&2
  exit 1
fi

mkdir -p modules
destination="modules/${asset_name}"
partial="${destination}.part"
rm -f "$partial"
if ! curl --fail --location --silent --show-error "${curl_auth[@]}" --output "$partial" "$asset_url"; then
  rm -f "$partial"
  exit 1
fi
mv -f "$partial" "$destination"
printf 'Downloaded %s (%s) from https://github.com/%s/releases/tag/%s\n' \
  "$destination" "$asset_name" "$repo" "$tag"
