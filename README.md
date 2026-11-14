# Neural Passthrough (Transparency for macOS)

A native macOS application providing real-time, ultra-low latency audio transparency and passthrough mode. It captures ambient audio via your default input device (microphone) and routes it directly to your output device (headphones/speakers) with minimal latency, digital signal processing, dynamic range compression, and speech frequency optimization.

![macOS](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Release](https://img.shields.io/github/v/release/haqorayush/Neural-PassThrough?color=green&label=download%20dmg)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📥 Direct Download (DMG)

You can download the pre-built, ready-to-use macOS disk image directly without needing to compile code or run terminal commands:

👉 **[Download Transparency.dmg (Latest Release)](https://github.com/haqorayush/Neural-PassThrough/releases/latest)**

1. Download `Transparency.dmg`.
2. Double-click the `.dmg` to open it.
3. Drag **Transparency** into your **Applications** folder.
4. Launch Transparency from Applications or Spotlight.

---

## ✨ Features

- **Symmetric 2×2 Widescreen Dashboard**:
  - **Audio Engine & Hardware**: Master transparency toggle with keyboard shortcut indicator, plus a 2×3 live telemetry grid for Input, Output, Sample Rate, Channels, Format, and Latency.
  - **Microphone Mode (DSP Engine)**: Instant switching between **Standard** (light noise reduction), **Voice Isolation** (Apple ML neural background noise cancellation), and **Wide Spectrum** (pure ambient acoustic passthrough), with direct access to macOS Control Center.
  - **Signal & Amplification**: Real-time decibel meter (`dB`), ballistic decay level meter, and output amplification slider (0% to 200%) with hearing damage protection warnings.
  - **Preferences**: Launch at login toggle (`SMAppService`), global hotkey configuration, and clean shutdown.
- **Ultra-Low Latency Pipeline**: Direct CoreAudio / `AVAudioEngine` routing with minimal I/O buffer frames (~1.33 ms presentation latency).
- **Menu Bar Accessory & Widescreen Window**: Sleek menu bar item with live ECG waveform pulse animations and an expansive widescreen settings console.
- **Global Shortcut**: Press <kbd>⌥ Option</kbd> + <kbd>⇧ Shift</kbd> + <kbd>T</kbd> anywhere in macOS to instantly toggle transparency mode on/off.
- **Auto-Start**: Built-in support for Launch at Login.
- **Dynamic Device Switching**: Automatically adapts on the fly when headphones or microphones are connected or disconnected.

---

## Requirements

- macOS 13.0 (Ventura) or later
- Microphone permissions for audio capture
- (Optional, for building from source) Swift 5.9+ / Xcode Command Line Tools

---

## 🛠️ Building From Source

If you prefer building from source:

### 1. Clone the Repository
```bash
git clone https://github.com/haqorayush/Neural-PassThrough.git
cd Neural-PassThrough
```

### 2. Build the Application Bundle
```bash
./build.sh
```
This compiles the Swift source and generates a signed `Transparency.app` in the project directory.

### 3. Package as a Disk Image (.dmg)
```bash
./package_dmg.sh
```
Generates a standalone, compressed `Transparency.dmg` with an Applications drag-and-drop installer symlink.

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| <kbd>⌥ Option</kbd> + <kbd>⇧ Shift</kbd> + <kbd>T</kbd> | Toggle transparency passthrough anywhere |

---

## 📁 Project Structure

```
Neural-PassThrough/
├── .github/
│   └── workflows/
│       └── release.yml     # Automated GitHub Actions workflow to build & publish DMG
├── main.swift              # SwiftUI dashboard, CoreAudio engine, DSP chain, hotkeys
├── AppIcon.icns            # macOS application icon bundle
├── MyIcon.iconset/         # Iconset source images (16x16 to 512x512@2x)
├── entitlements.plist      # macOS audio input entitlements
├── build.sh                # App bundle compilation and codesigning script
├── package_dmg.sh          # DMG installer disk image packaging script
├── test.swift              # CoreAudio dynamics processor unit test
├── test_audio.swift        # CoreAudio device enumeration helper
└── README.md               # Documentation
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
