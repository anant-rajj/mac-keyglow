# KeyGlow ⌨️✨

> **Ultra-lightweight, zero-dependency native macOS Menu Bar controller & animation studio for MacBook keyboard backlights.**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-blue)]()
[![Language](https://img.shields.io/badge/Language-Swift%206-orange?logo=swift)](https://swift.org)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero-success)]()
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**KeyGlow** is a native macOS status bar menu app and command-line utility that unlocks programmatic control and hardware lighting animations for your MacBook keyboard backlight. Written in pure Swift with zero external dependencies and < 8MB RAM footprint, KeyGlow works seamlessly on all **Apple Silicon (M1, M2, M3, M4)** and **Intel** MacBooks without requiring `sudo` or kernel extensions.

---

## ✨ Features

* **Minimalist Menu Bar Dashboard**: Lives in your macOS menu bar as a lightweight status item. Access brightness sliders, instant presets, and animation modes in one click.
* **6 Native Hardware Animations**:
  * 🫁 **Breathing Glow**: Hypnotic sinusoidal breathing pulse inspired by classic Apple unibody sleep indicators.
  * ⚡ **Disco Strobe**: High-energy rhythmic strobe flashing, perfect for music sessions or build notifications.
  * 💓 **Heartbeat Pulse**: Organic dual-peak cardiac rhythm simulation (systole & diastole phases).
  * 🌊 **Harmonic Wave**: Multi-frequency compound sinusoidal light swells.
  * 📡 **Optical Morse Code**: Encodes and flashes any text message as optical Morse code dots and dashes.
  * ⌨️ **Reactive Typing Glow**: Illuminates your keyboard while typing and gently decays into darkness when idle.
* **Power-User Command-Line Interface (CLI)**: Automate keyboard light states, trigger strobes upon compiler completion, or integrate with shell scripts and agent loops.
* **Safe Hardware Restoration**: Traps termination signals (`SIGINT`, `SIGTERM`) and application quits to safely restore your original ambient brightness level.
* **100% Offline & Private**: Zero telemetry, zero analytics, zero network requests, and zero background daemons.

---

## 🖥️ System Compatibility

| Component | Requirement |
| :--- | :--- |
| **Operating System** | macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia) or later |
| **Hardware** | Any MacBook Pro or MacBook Air with a built-in backlit keyboard |
| **Architecture** | Apple Silicon (`arm64`: M1 / M2 / M3 / M4) and Intel (`x86_64`) |
| **Privileges** | Standard user account (No `sudo` / root required) |

---

## 🚀 Installation & Build

### Quick One-Liner (Build & Install App)

```bash
git clone https://github.com/anant-rajj/mac-keyglow.git
cd mac-keyglow
make app
open KeyGlow.app
```

To install the standalone app into `/Applications`:
```bash
make install-app
```

To install the `keyglow` CLI command into `/usr/local/bin`:
```bash
make install
```

---
## 💻 Command-Line Usage (CLI)

KeyGlow doubles as a scriptable terminal command. Run `keyglow --help` to inspect all options:

```bash
# View current status and hardware backlight ID
keyglow status

# Get current brightness value (0.00 to 1.00)
keyglow get

# Set brightness manually (supports decimals or percentage)
keyglow set 0.75
keyglow set 80%
keyglow max
keyglow off

# Run breathing glow at 14 breaths/minute for 10 seconds
keyglow breathe 14 -d 10

# Flash a disco strobe at 130 BPM for 5 seconds (great for build alerts!)
keyglow disco 130 -d 5

# Cardiac heartbeat pulse
keyglow heartbeat 72

# Optical Morse code beacon
keyglow morse "SOS" -d 15

# Reactive typing glow (lights up while typing, fades when idle)
keyglow typing
```

### Practical Integration Example (Build Notifications)

Flash your keyboard backlight 3 times when a build or long script completes:

```bash
cargo build --release && keyglow disco 140 -d 3
```

---

## 🔬 How It Works Under the Hood

MacBook keyboards share a unified Pulse-Width Modulation (PWM) power rail managed by Apple's System Management Controller (Intel) or Power Management Unit (Apple Silicon). macOS exposes control over this rail through the private `CoreBrightness.framework` via `KeyboardBrightnessClient`.

KeyGlow connects directly to this interface dynamically using Swift runtime reflection, eliminating external library bloat and avoiding fragile private header imports:

```
┌──────────────────────────────────────────────┐
│        KeyGlow (Menu Bar App & CLI)          │
└──────────────────────┬───────────────────────┘
                       │ Dynamic dlopen / objc runtime
                       ▼
┌──────────────────────────────────────────────┐
│   /System/Library/PrivateFrameworks/         │
│   CoreBrightness.framework                   │
│   (`KeyboardBrightnessClient`)               │
└──────────────────────┬───────────────────────┘
                       │ IOKit / PWM Duty Cycle
                       ▼
┌──────────────────────────────────────────────┐
│   MacBook Keyboard Backlight Hardware Rail   │
└──────────────────────────────────────────────┘
```

---

## 🔒 Privacy & Safety Guarantee

* **No Network Calls**: Contains no sockets, networking libraries, or external URLs.
* **No Telemetry**: No tracking, metrics, analytics, or user identifiers.
* **No Root Privileges**: Runs entirely in unprivileged user space.
* **Clean State Exit**: Always restores your original brightness upon exit or interruption.

---

## 📄 License

Released under the [MIT License](LICENSE).
