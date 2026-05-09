#!/bin/bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GCLOUD_INSTALL_DIR="/home/user"
GCLOUD_BIN="$GCLOUD_INSTALL_DIR/google-cloud-sdk/bin"

# Install Google Cloud SDK if not present
if [ ! -f "$GCLOUD_BIN/gcloud" ]; then
  echo "Installing Google Cloud SDK..."
  curl -sSL https://sdk.cloud.google.com | bash -s -- --disable-prompts --install-dir="$GCLOUD_INSTALL_DIR"
fi

# Add gcloud to PATH for this session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$GCLOUD_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

echo "Google Cloud SDK ready at $GCLOUD_BIN"
