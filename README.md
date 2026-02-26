# MissionControl-Mac

Desktop control surface for OpenClaw Gateway.

## What it does

- Connects to an OpenClaw Gateway instance with Bearer token auth
- Runs live health checks and periodic polling
- Streams model responses into local sessions
- Stores local app state (sessions/events/journal/cron summaries)

## Quick start

1. Open `MissionControl-Mac.xcodeproj` in Xcode.
2. Build/run the macOS app target.
3. In **Settings**, configure:
   - Gateway URL (example: `http://127.0.0.1:18789`)
   - Gateway token
   - Session key (default: `agent:main:main`)
   - Model alias/name

## Security notes

- Gateway token is stored in macOS Keychain (`service: MissionControl-Mac`)
- Local app state is stored in `UserDefaults`
- Avoid committing secrets, certificates, provisioning files, or `.env` files

## Production hardening checklist

- [ ] Add CI build checks for PRs
- [ ] Add unit tests for API parsing and URL construction
- [ ] Add request retry policy for transient failures
- [ ] Add structured logging + export option
- [ ] Add release signing and notarization workflow
