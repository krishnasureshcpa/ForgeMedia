# ForgeMedia Privacy-First Product Policy

## Product promise

ForgeMedia is a privacy-first local media processing app.

The default posture is:

> Privacy On.

ForgeMedia should not send user media, transcripts, prompts, job history, file names, output paths, or usage analytics to external services by default.

## Default privacy behavior

By default:

- No telemetry.
- No analytics collection.
- No cloud upload.
- No remote crash-report upload.
- No media sent to third-party AI services.
- No automatic sharing of job history.
- No background network calls except explicitly enabled local services.

The app should work fully offline for core media workflows where possible.

## Optional local data

ForgeMedia may store data on the user’s device only when it improves the user experience.

Examples:

- Job queue.
- Processing history.
- Presets.
- Media metadata cache.
- Transcript cache.
- Agent prompt history.
- Output validation records.
- Crash logs stored locally for user inspection.

All local data should be:

- User-owned.
- Easy to inspect.
- Easy to export.
- Easy to delete.
- Clearly separated from cloud services.

## Optional network/local AI behavior

Network or local AI features must be explicit and reversible.

Examples:

- Ollama local API at `localhost:11434`.
- Local MCP tools.
- User-selected remote model endpoints, if ever added.
- Optional cloud fallback, if ever added.

Rules:

- Local-first is the default.
- Remote services require explicit opt-in.
- The user should see what is being sent.
- The user should be able to disable the feature later.
- Sensitive media should never be sent without clear confirmation.

## Privacy settings

Recommended settings screen:

```text
Privacy
[✓] Privacy On
[ ] Allow optional local usage history
[ ] Allow local crash logs for troubleshooting
[ ] Allow local transcript cache
[ ] Allow local agent prompt history
[ ] Allow local Ollama integration
[ ] Allow remote AI services
```

Default state:

- Privacy On: enabled.
- Optional local history: disabled or minimal.
- Remote AI services: disabled.

## User-facing language

Use calm, direct copy:

- “Your media stays on your Mac.”
- “No telemetry. No analytics. No cloud uploads by default.”
- “Privacy is on by default.”
- “You can keep optional local history to make repeat jobs faster.”
- “Remote AI is off unless you enable it.”

Avoid vague language like:

- “We may use data to improve services.”
- “Anonymous analytics.”
- “Cloud processing may occur.”

## Customer benefit

Privacy-first is a selling point because many creators, studios, families, and professionals process sensitive or unreleased media.

ForgeMedia should position privacy as:

- Faster local workflows.
- Safer handling of private footage.
- No surprise uploads.
- No subscription dependency for core processing.
- More trust from professional users.

## Engineering requirements

- Do not initialize analytics SDKs.
- Do not include telemetry endpoints.
- Do not upload crash reports automatically.
- Store local logs in user-controlled app support directories.
- Provide clear delete/export controls.
- Keep remote endpoints disabled by default.
- Add tests that assert no network calls are made during default media jobs.
