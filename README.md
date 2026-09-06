# Neural Passthrough (Transparency for macOS)

A native macOS menu bar application providing real-time, ultra-low latency audio transparency and passthrough mode. It captures ambient audio via your default input device (microphone) and routes it directly to your output device (headphones/speakers) with minimal latency, digital signal processing, dynamic range compression, and speech frequency optimization.

![macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Features

- **Ultra-Low Latency Pipeline**: Direct CoreAudio / `AVAudioEngine` routing with minimal I/O buffer frames.
- **Menu Bar Accessory**: Clean, unobtrusive SwiftUI menu bar interface with real-time waveform pulse animations.
- **Hardware Telemetry & Metrics**: Real-time display of:
  - Input & Output active audio devices
  - Sample rate (e.g. 48.0 kHz) and channel count
  - Audio format (e.g. 32-bit Float)
  - Measured hardware + engine presentation latency (in ms)
  - Real-time signal decibel meter (dB)
  - Active session uptime counter
- **Audio DSP Chain**:
  - High-pass filter to eliminate low-frequency rumble and wind noise
  - Dynamics compression & noise gating for balanced speech clarity
  - Up to 200% volume amplification with clipping & hearing safety warnings
- **Global Shortcut**: Press <kbd>⌥ Option</kbd> + <kbd>⇧ Shift</kbd> + <kbd>T</kbd> anywhere in macOS to instantly toggle transparency mode on/off.
- **Auto-Start**: Built-in support for Launch at Login (`SMAppService`).
- **Device Reconfiguration Handling**: Automatically adapts when headphones or microphones are plugged in or disconnected.

---

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+ / Xcode Command Line Tools
- Microphone permissions for audio capture

---

## Quick Start

### 1. Build the App
Clone the repository and run the build script:

```bash
git clone https://github.com/haqorayush/neural-passthrough.git
cd neural-passthrough
./build.sh
```

This compiles the Swift source and generates a signed `Transparency.app` bundle in the project directory.

### 2. Run the App
Launch the app directly from your terminal or open it in Finder:

```bash
open Transparency.app
```

### 3. Grant Microphone Permission
When first launched, macOS will prompt you to grant microphone permissions so ambient audio can be passed through to your headphones.

---

## Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| <kbd>⌥ Option</kbd> + <kbd>⇧ Shift</kbd> + <kbd>T</kbd> | Toggle passthrough on/off |

---

## Project Structure

```
neural-passthrough/
├── main.swift           # Main SwiftUI app, CoreAudio engine, DSP chain, hotkeys
├── AppIcon.icns         # macOS application icon bundle
├── MyIcon.iconset/      # Iconset source images (16x16 to 512x512@2x)
├── entitlements.plist   # macOS audio input entitlements
├── build.sh             # Bundle compilation and packaging script
├── test.swift           # CoreAudio dynamics processor unit test
├── test_audio.swift     # CoreAudio device enumeration helper
└── README.md            # Documentation
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
