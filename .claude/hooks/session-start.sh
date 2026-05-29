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

# Authenticate using service account key if available
KEY_FILE="${GOOGLE_APPLICATION_CREDENTIALS:-}"
if [ -n "$KEY_FILE" ] && [ -f "$KEY_FILE" ]; then
  echo "Authenticating with service account key: $KEY_FILE"
  "$GCLOUD_BIN/gcloud" auth activate-service-account --key-file="$KEY_FILE"
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$KEY_FILE\"" >> "$CLAUDE_ENV_FILE"
  fi
else
  echo "No service account key found. Set GOOGLE_APPLICATION_CREDENTIALS to a key file path for automatic auth."
fi

echo "Google Cloud SDK ready at $GCLOUD_BIN"
