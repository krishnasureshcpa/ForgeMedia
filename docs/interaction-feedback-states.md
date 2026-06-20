# ForgeMedia Interaction and Progress Feedback States

This document defines how ForgeMedia should communicate work that can take seconds, minutes, or hours. The goal is meaningful visibility: users should understand what is happening, why it matters, and what they can do without feeling like the app is noisy or demanding attention.

## Core principles

1. **Show phase before percentage**: users trust "Transcribing segment 8 of 14" more than a raw progress number.
2. **Show confidence**: distinguish unknown, estimated, and measured progress.
3. **Show recovery**: long jobs should preserve partial outputs and explain resume/cancel behavior.
4. **Show privacy posture**: any remote/local AI handoff needs explicit copy before work starts.
5. **Show restraint**: progress feedback should be calm, not theatrical.
6. **Show accessibility**: every animated indicator needs a text label and live-region support.

## Job lifecycle states

### 1. Idle / ready

Shown when a media item is loaded and the app is ready to accept an action.

Must include:

- Media title or filename
- Detected duration, resolution, codec, and stream summary when available
- Primary action, such as "Transcribe", "Export", "Restore", or "Run quality check"
- Privacy status, such as "Privacy On: local processing"

Copy example:

> Privacy On. This job will run locally on your Mac.

### 2. Preparing

Shown while the app probes the file, calculates output size, checks disk space, and builds a resumable plan.

Progress style:

- Use a subtle spinner or skeleton.
- Do not show a percentage until the plan exists.
- If preparation exceeds 15s, show a fallback message.

Copy examples:

- "Checking video streams…"
- "Estimating output size…"
- "Preparing 14 resumable segments…"

### 3. Running

Shown while work is underway.

Must include:

- Current phase
- Determinate or estimated progress
- Elapsed time
- Estimated remaining time if confidence is meaningful
- Cancel/pause availability
- Destination path
- Last update timestamp for long jobs

Copy examples:

- "Transcribing segment 8 of 14…"
- "Exporting segment 11 of 14…"
- "Checking audio sync…"
- "Writing final output…"

Progress display rules:

- Use determinate progress when segment count or byte range is known.
- Use indeterminate progress only during short phases with unknown duration.
- Stop indeterminate motion after 60s and show a recovery/error state.
- Throttle UI updates so long jobs do not cause menu bar churn.

### 4. Taking longer than expected

Triggered after 15s for slow phases or after a phase-specific threshold.

Must include:

- Current phase
- Whether cancellation is safe
- Whether partial output is being preserved
- Next automatic update or retry behavior

Copy examples:

- "This phase is taking longer than expected. You can keep working; the job will continue in the background."
- "Large file detected. Processing is continuing locally and partial output will be saved."

### 5. Paused

Shown when the user pauses a job or the app pauses for resource protection.

Must include:

- Reason for pause
- Completed segments or byte range
- Resume action
- Whether temporary files are safe

Copy examples:

- "Paused after segment 6 of 14. Resume from the last safe checkpoint."
- "Paused to protect system responsiveness. Resume when you are ready."

### 6. Completed

Shown when the job finishes and validation passes.

Must include:

- Completed action
- Output location
- Duration
- Key quality checks
- Open output action
- Secondary action, such as "Share", "Open folder", or "Run another job"

Copy examples:

- "Transcript complete. Output saved in Movies/ForgeMedia."
- "Export complete. Duration, codec, and audio layout matched the source."

### 7. Completed with warnings

Shown when output is usable but a non-blocking issue was found.

Must include:

- Warning summary
- What remains usable
- What needs attention
- Primary recovery action

Copy examples:

- "Export complete, but audio layout could not be verified."
- "Subtitle timing looks good. One chapter marker was missing."

### 8. Failed

Shown when the job cannot continue.

Must answer:

1. What happened.
2. Why, if known.
3. What the user can do next.

Must include:

- Error summary in plain language
- Preserved inputs
- Preserved partial outputs if any
- Retry action
- Contact/support path after repeated failures

Copy examples:

- "Could not read the video stream. Try another file or choose FFmpeg probing."
- "Not enough disk space for the selected output. Free space or choose a smaller preset."

### 9. Canceled

Shown when the user cancels a job.

Must include:

- What was stopped
- What was cleaned up
- What partial output remains, if any
- Resume or delete action

Copy examples:

- "Canceled. Temporary files were removed. No output was created."
- "Canceled after segment 9 of 14. Partial output is saved and can be resumed."

### 10. Recovered

Shown after app relaunch or crash recovery.

Must include:

- Recovered job identity
- Last known phase
- Partial output status
- Resume, retry, or discard actions

Copy examples:

- "Recovered an unfinished export from yesterday. Resume from segment 9 of 14?"
- "Found a partial transcript cache. Use it or start fresh?"

## Progress confidence labels

Use these labels when progress is not exact:

| Label | Meaning |
|---|---|
| "Estimated" | Based on file size, segment count, or historical local timing |
| "Measured" | Based on completed segments, byte range, or engine progress |
| "Unknown" | Engine cannot report progress yet |
| "Validating" | Work is complete but output checks are still running |

## Output formation states

When the app produces a meaningful output, show how it formed without overwhelming the user.

### Transcript formation

Show:

- Segments completed
- Language/model/preset
- Cache status
- Confidence or quality notes when available
- Output path

Avoid showing raw Whisper tokens or verbose logs in the main UI.

### Export formation

Show:

- Source stream summary
- Selected preset
- Segment count
- Current encode phase
- Output container, codec, resolution, bitrate, and audio layout
- Validation checks

### Restoration / upscaling formation

Show:

- Source quality gate
- Frame or segment range
- Model/engine version
- Objective checks when available, such as PSNR/SSIM/VMAF-style comparison, loudness, or subtitle timing sanity
- Known limitations

## Feedback surfaces

### Menu bar

Use only compact state:

- Current phase
- Progress percentage or "Waiting…"
- Pause/cancel/open output
- Privacy On indicator when relevant

Avoid verbose logs in the menu bar.

### Main window

Use richer detail:

- Job timeline
- Current phase
- Progress confidence
- Quality checks
- Output destination
- Recovery actions

### Processing sheet

Use the most detailed view:

- Step list
- Engine progress
- Logs collapsed by default
- Expandable diagnostics
- Cancel/pause controls
- Last update time

## Error recovery rules

- First retry fires immediately.
- Second and third retries use exponential backoff: 2s, 4s, 8s max.
- After 3 failed retries, replace "Retry" with "Contact support" plus a copyable error ID.
- Preserve user input and selected settings across failures.
- Do not clear form fields when validation fails.
- Do not blame the user for engine failures.

## Accessibility requirements

- `role="status"` for non-urgent progress updates.
- `role="alert"` for blocking errors.
- `aria-live="polite"` for phase changes.
- `aria-live="assertive"` for failures that require action.
- Do not move focus to spinners.
- Move focus to loaded output details after a user-initiated action completes.
- Auto-dismissing toasts must be pauseable on hover/focus.
- Reduced-motion users should see static phase labels and progress values.

## Copy guidelines

Use calm, direct, product-specific language.

Good:

- "Reading video stream…"
- "Splitting into 14 segments…"
- "Transcribing segment 8 of 14…"
- "Checking audio sync…"
- "Writing output to Movies/ForgeMedia…"
- "Privacy On: this job stays on your Mac."

Avoid:

- "Working…"
- "Almost done…"
- "Processing your file…"
- "Something went wrong."
- "Hollywood-grade enhancement running…"
- "We may use your data to improve services."

## Review checklist

- [ ] Every long-running job has a running, paused, canceled, failed, recovered, and completed state.
- [ ] Progress copy names the current phase.
- [ ] Indeterminate motion has a timeout.
- [ ] Errors explain cause and recovery.
- [ ] Partial outputs are described honestly.
- [ ] Privacy changes are explicit before remote/local AI work starts.
- [ ] Menu bar feedback stays compact.
- [ ] Main window feedback is scannable.
- [ ] Processing details are available without flooding the user.
