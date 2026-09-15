# opencode-server

Docker image wrapping [OpenCode](https://opencode.ai)
(`github.com/sst/opencode`) server mode (`opencode serve`), published to GHCR
for use by [docker-infra](https://github.com/DavidWinterbottom-2/docker-infra)
(`home-docker/services/opencode/`).

No official Docker image exists for OpenCode as of building this (checked:
no `sst/opencode` on Docker Hub, GHCR denies the obvious repo names). This
builds `node:22-slim` + `npm ci` against the committed `package-lock.json`,
which pins `opencode-ai` and every platform `optionalDependency` (including
`opencode-linux-arm64`) exactly, rather than an unpinned `npm install -g`.

`.github/workflows/publish.yml` builds and pushes
`ghcr.io/davidwinterbottom-2/opencode-server` (multi-arch: `linux/amd64` +
`linux/arm64`) on every push to `main`, tagged `latest` and `sha-<commit>`.

## Configuration (all via env vars — nothing is baked into the image)

| Variable | Required | Purpose |
| --- | --- | --- |
| `OPENCODE_API_KEY` | yes | API key for the OpenAI-compatible provider |
| `OPENCODE_BIND` | yes | IP for `opencode serve --hostname` to bind |
| `OPENCODE_PROVIDER_BASE_URL` | yes | Base URL of the OpenAI-compatible backend (e.g. an Open WebUI or Ollama instance) |
| `OPENCODE_PROVIDER_NAME` | no | Display name for the provider (default `Custom provider`) |
| `OPENCODE_PROVIDER_MODEL` | no | Model id to register (default `qwen2.5-coder:32b`) |
| `OPENCODE_PORT` | no | Port `opencode serve` listens on (default `4096`) |
| `REQUIRE_BIND_INTERFACE` | no | If set (e.g. `tailscale0`), refuses to start unless `OPENCODE_BIND` is actually bound to that interface — defense-in-depth since `opencode serve` has no built-in authentication of its own |

`entrypoint.sh` writes `opencode.json` and `auth.json` from these at
container start, so no config file or secret is ever baked into the image.

## Updating the pinned opencode-ai version

Edit `package.json`, run `npm install --package-lock-only` to refresh
`package-lock.json`, commit both, push to `main` — the workflow rebuilds and
republishes automatically.
