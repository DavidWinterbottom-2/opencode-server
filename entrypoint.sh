#!/bin/sh
# Generic entrypoint: this image is configured entirely by env vars, no
# baked-in provider/host assumptions, so it's reusable outside docker-infra.
set -eu

: "${OPENCODE_API_KEY:?OPENCODE_API_KEY must be set}"
: "${OPENCODE_BIND:?OPENCODE_BIND must be set}"
: "${OPENCODE_PROVIDER_BASE_URL:?OPENCODE_PROVIDER_BASE_URL must be set}"

# opencode serve has no built-in authentication. Optional defense-in-depth:
# set REQUIRE_BIND_INTERFACE to a network interface name (e.g. tailscale0)
# and this refuses to start unless OPENCODE_BIND is actually bound to it —
# an enforced check instead of trusting the deployer's .env. Leave unset to
# skip (e.g. if the caller already fully controls network placement).
if [ -n "${REQUIRE_BIND_INTERFACE:-}" ]; then
  if ! ip -4 -o addr show "${REQUIRE_BIND_INTERFACE}" 2>/dev/null | grep -q " inet ${OPENCODE_BIND}/"; then
    echo "FATAL: OPENCODE_BIND (${OPENCODE_BIND}) is not an address on interface '${REQUIRE_BIND_INTERFACE}'." >&2
    echo "opencode serve has no built-in authentication — refusing to start on an unverified interface." >&2
    exit 1
  fi
fi

mkdir -p "${HOME}/.config/opencode"
cat > "${HOME}/.config/opencode/opencode.json" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "custom": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "${OPENCODE_PROVIDER_NAME:-Custom provider}",
      "options": { "baseURL": "${OPENCODE_PROVIDER_BASE_URL}" },
      "models": { "${OPENCODE_PROVIDER_MODEL:-qwen2.5-coder:32b}": {} }
    }
  }
}
EOF

# Real key lives only in the deployer's env, never in the image or a
# committed file.
mkdir -p "${HOME}/.local/share/opencode"
cat > "${HOME}/.local/share/opencode/auth.json" <<EOF
{"custom": {"type": "api", "key": "${OPENCODE_API_KEY}"}}
EOF
chmod 600 "${HOME}/.local/share/opencode/auth.json"

exec opencode serve --hostname "${OPENCODE_BIND}" --port "${OPENCODE_PORT:-4096}"
