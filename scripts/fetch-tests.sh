#!/bin/sh

# Fetches the woodland journey tests co-located in grants-config-woodland
# (test/grants-ui), along with the GAS schema they validate against, at the
# latest config release tag. Mirrors how grants-ui resolves WOODLAND_TAG in
# tools/docker-compose-smoke-test.sh. Set WOODLAND_TAG to pin a release.

set -e

REPO="DEFRA/grants-config-woodland"
DEST=".woodland-config"

# On CDP, outbound traffic to GitHub must go via the egress proxy. Scoped to
# these curl calls so the browser's route to grants-ui is unaffected.
PROXY="${CDP_HTTPS_PROXY:-$CDP_HTTP_PROXY}"

fetch() {
  if [ -n "$PROXY" ]; then
    curl -sSfL --ssl-no-revoke --proxy "$PROXY" "$@"
  else
    curl -sSfL --ssl-no-revoke "$@"
  fi
}

if [ -z "$WOODLAND_TAG" ]; then
  TAGS=$(fetch "https://api.github.com/repos/$REPO/tags") || {
    echo "Error: Could not fetch woodland tags from GitHub"
    exit 1
  }
  WOODLAND_TAG=$(printf '%s' "$TAGS" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{process.stdout.write(JSON.parse(d)[0]?.name ?? '')}catch{}})")
fi

if [ -z "$WOODLAND_TAG" ]; then
  echo "Error: Could not fetch woodland tag"
  exit 1
fi

echo "Using woodland journey tests at version $WOODLAND_TAG"
ARCHIVE="$(mktemp)"
fetch "https://codeload.github.com/$REPO/tar.gz/refs/tags/$WOODLAND_TAG" -o "$ARCHIVE" || {
  echo "Error: Could not download grants-config-woodland $WOODLAND_TAG"
  rm -f "$ARCHIVE"
  exit 1
}
rm -rf "$DEST"
mkdir -p "$DEST"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$DEST"
rm -f "$ARCHIVE"
echo "Saved to $DEST"
