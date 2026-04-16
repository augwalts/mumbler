# Mumbler

A lightweight macOS menu bar app that transcribes your voice and pastes the text into whatever you're working on.

**Click the mic icon in the menu bar to start recording. Click again to stop. Text appears at your cursor.**

## Features

- **Auto-paste** — transcript goes directly into the active text field
- **On-device transcription** via Apple Speech framework (no data leaves your Mac)
- **Live transcript preview** in the menu bar popover
- **Auto-restart** — recordings over 1 minute are handled seamlessly (Speech framework limit)
- **Menu bar only** — no dock icon, stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- Swift toolchain (Command Line Tools)

## Build & Install

```bash
./build.sh
```

This builds the Swift package, creates `Mumbler.app`, signs it with the "Mumbler Dev" certificate, and installs to `~/Applications/`.

### First-time setup: Create signing certificate

The app uses a self-signed certificate so Accessibility permission persists across rebuilds. Create it once:

```bash
# Generate certificate
cat > /tmp/mumbler-cert.conf <<'EOF'
[req]
distinguished_name = req_dn
x509_extensions = codesign
prompt = no
[req_dn]
CN = Mumbler Dev
[codesign]
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
basicConstraints = critical, CA:false
EOF

openssl req -x509 -newkey rsa:2048 \
  -keyout /tmp/mumbler-key.pem -out /tmp/mumbler-cert.pem \
  -days 3650 -nodes -config /tmp/mumbler-cert.conf

openssl pkcs12 -export -out /tmp/mumbler-cert.p12 \
  -inkey /tmp/mumbler-key.pem -in /tmp/mumbler-cert.pem \
  -passout pass:mumbler -legacy

security import /tmp/mumbler-cert.p12 \
  -k ~/Library/Keychains/login.keychain-db \
  -T /usr/bin/codesign -P "mumbler"

rm /tmp/mumbler-cert.conf /tmp/mumbler-key.pem /tmp/mumbler-cert.pem /tmp/mumbler-cert.p12
```

### Why ~/Applications/?

macOS 26 rejects ad-hoc and self-signed apps launched from `/Applications/`. The app must live in `~/Applications/` instead. The build script handles this automatically.

## Permissions

On first launch, grant these three permissions:

1. **Microphone** — auto-prompted on first recording
2. **Speech Recognition** — auto-prompted on first recording
3. **Accessibility** — must be granted manually: System Settings > Privacy & Security > Accessibility > add `~/Applications/Mumbler.app`

Accessibility is required for auto-paste (simulates Cmd+V). Without it, the transcript is still copied to your clipboard — you just need to Cmd+V manually.

## Usage

| Action | How |
|--------|-----|
| Start/stop recording | Click the menu bar mic icon > press the record button |
| Copy last transcript | Click "Copy" in the menu bar popover |
| Disable auto-paste | Uncheck "Auto-paste after recording" (copies to clipboard instead) |
| Quit | Menu bar > Quit Mumbler |

## Debugging

Run from Terminal to see timestamped logs:

```bash
~/Applications/Mumbler.app/Contents/MacOS/Mumbler
```

**Important:** Do not run from Claude Code's `!` command — it backgrounds the process and you won't see output. Use a real Terminal/iTerm window.

Example log output:
```
[2026-04-01T17:13:23.404Z] Recording started
[2026-04-01T17:13:23.492Z] Using on-device speech recognition
[2026-04-01T17:13:23.492Z] Transcription started (generation 1)
[2026-04-01T17:13:24.265Z] Audio format: 1 ch, 16000.0 Hz
[2026-04-01T17:13:24.283Z] Audio engine started
[2026-04-01T17:13:54.810Z] Recording stopped — waiting for transcription
[2026-04-01T17:13:55.172Z] Final transcript: ...
[2026-04-01T17:13:55.172Z] Final result received (217 chars)
```

## Architecture

```
MumblerApp.swift          → SwiftUI entry point, menu bar icon
  └─ AppState.swift       → Central state, coordinates recording flow
       ├─ AudioRecorder       → AVAudioEngine mic capture
       ├─ SpeechTranscriber   → SFSpeechRecognizer (on-device)
       └─ PasteService        → Clipboard swap + CGEvent Cmd+V
MenuBarView.swift         → Record button, transcript display, settings
Permissions.swift         → Mic, Speech, Accessibility checks
Logger.swift              → Timestamped print() for Terminal debugging
Constants.swift           → Timing values, app name
```

## How It Works

1. Audio captured via `AVAudioEngine` (1ch, 16kHz)
2. Streamed to `SFSpeechRecognizer` for live transcription
3. If Speech framework hits ~1min limit, transcription auto-restarts (audio keeps flowing)
4. On stop: final transcript copied to clipboard
5. `CGEvent` simulates Cmd+V to paste into active app (requires Accessibility)
6. Original clipboard restored after paste

## Known Limitations

- Apple Speech framework has a ~1 minute continuous recognition limit (auto-restart handles this)
- Accessibility permission must be granted manually in System Settings
- On-device recognition quality depends on the macOS speech model for your locale
- Global hotkey not yet implemented (issue #5)
