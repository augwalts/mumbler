# Mumbler

A lightweight macOS menu bar app that transcribes your voice and pastes the text into whatever you're working on.

**Press Option+Space to start recording. Press again to stop. Text appears at your cursor.**

## Features

- **Global hotkey** (Option+Space) works from any app
- **Auto-paste** — transcript goes directly into the active text field
- **On-device transcription** via Apple Speech framework (no data leaves your Mac)
- **Floating indicator** shows recording status and live transcript preview
- **Toggle or hold-to-record** modes (configurable)
- **Menu bar only** — no dock icon, stays out of your way

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- Swift toolchain (Command Line Tools)

## Build

```bash
./build.sh
```

This builds the Swift package and creates `Mumbler.app`.

## Install

```bash
cp -r Mumbler.app /Applications/
open /Applications/Mumbler.app
```

## Permissions

On first launch, grant these three permissions:

1. **Microphone** — auto-prompted
2. **Speech Recognition** — auto-prompted
3. **Accessibility** — System Settings > Privacy & Security > Accessibility > enable Mumbler

Accessibility is required for auto-paste (simulates Cmd+V in the active app).

## Usage

| Action | How |
|--------|-----|
| Start/stop recording | Press `Option+Space` |
| Toggle recording | Click the menu bar mic icon > Start/Stop Recording |
| Copy last transcript | Menu bar > Copy Last Transcript |
| Switch to hold-to-record | Menu bar > Hold to record checkbox |
| Disable auto-paste | Menu bar > Auto-paste checkbox (copies to clipboard instead) |

## How It Works

1. Audio captured via `AVAudioEngine`
2. Streamed to `SFSpeechRecognizer` for live transcription
3. Final transcript copied to clipboard
4. `CGEvent` simulates Cmd+V to paste into active app
5. Original clipboard restored after paste

## Known Limitations

- Apple Speech framework has a ~1 minute continuous recognition limit
- Accessibility permission must be granted manually in System Settings
- On-device recognition quality depends on the macOS speech model for your locale
