# KeyGlow ⌨️✨

> **Ultra-lightweight, zero-dependency native macOS Menu Bar controller, animation studio & gesture hub for MacBook keyboard backlights.**

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%7C%20Intel-blue)]()
[![Language](https://img.shields.io/badge/Language-Swift%206-orange?logo=swift)](https://swift.org)
[![Dependencies](https://img.shields.io/badge/Dependencies-Zero-success)]()
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**KeyGlow** is a native macOS status bar menu app and command-line utility that unlocks programmatic control, hardware lighting animations, and multi-touch gesture shortcuts for your MacBook keyboard backlight. Written in pure Swift with zero external dependencies and < 8MB RAM footprint, KeyGlow works seamlessly on all **Apple Silicon (M1, M2, M3, M4)** and **Intel** MacBooks without requiring `sudo` or kernel extensions.

---

## ✨ Features

### 🖥️ Native Menu Bar Dashboard
* Lives quietly in your macOS status bar (`LSUIElement = true`).
* Real-time continuous slider with exact percentage readout.
* Instant presets: `Off (0%)`, `Dim (20%)`, `Medium (50%)`, `Bright (80%)`, and `Max (100%)`.
* Built-in **ℹ️ Information & Gestures Guide** interactive guide window.

### 🤚 Multi-Touch & Force Touch Gestures
* **⌘ Command / Fn + Trackpad Horizontal Slide**: Adjust keyboard backlight brightness effortlessly by sliding your finger across the trackpad while holding `⌘ Command` or `Fn`.
* **Native Floating HUD Bezel**: Displays a live on-screen translucent bezel showing the brightness level and percentage while sliding.
* **4-Corner Force Touch Pressure Zones**: Press firmly on any of the 4 trackpad corners to trigger customizable hardware actions:
  * 🎯 **Top-Left Corner**: Instant Mute / Restore toggle.
  * 🔥 **Top-Right Corner**: Force Turbo Boost (ramps brightness to 100% while pressed).
  * 🎛️ **Bottom-Left Corner**: Cycle through animation modes.
  * ⚡ **Bottom-Right Corner**: Instant strobe burst.
* **Live Force Meter**: The floating HUD shows a real-time pressure gauge (0%–100%) reflecting Force Touch contact intensity.
* **Fully Customizable**: Toggle gestures and assign custom actions for all 4 corners from the Menu Bar menu.

### 🎨 8 Native Hardware Animations (Up to 100% Max Brightness)
* ⚡ **Instant Strike (Press Flash)**: Flashes instantly to 100% max brightness on keypress or mouse click, and drops to zero immediately upon release.
* 🫁 **Breathing Glow**: Hypnotic sinusoidal breathing pulse inspired by classic Apple unibody sleep indicators.
* 🕯️ **Candle Flame Flicker**: Warm, organic micro-flickering ambient glow.
* 💓 **Heartbeat Pulse**: Organic dual-peak cardiac rhythm simulation (systole & diastole phases).
* 🌊 **Harmonic Wave**: Multi-frequency compound sinusoidal light swells.
* ✨ **Disco Strobe**: High-energy rhythmic strobe flashing, perfect for music sessions or build notifications.
* 📡 **Optical Morse Code**: Encodes and flashes custom text messages as optical Morse code dots and dashes.
* ⌨️ **Reactive Typing Glow**: Illuminates your keyboard while typing and gently decays into darkness when idle.
* **Customizable Peak Brightness**: Configure maximum peak brightness up to **100%** (100%, 85%, 70%, 50%).

### 💻 Power-User CLI & Safe Hardware Handling
* Automate backlight states, trigger alerts on terminal build completion, or run timed animations from shell scripts.
* Intercepts `SIGINT` (Ctrl+C) and `SIGTERM` to restore original brightness safely.
* 100% offline, zero network requests, zero telemetry, and zero tracking.

---

## 🚀 Installation & Build

### Build & Launch Standalone App
```bash
git clone https://github.com/anant-rajj/mac-keyglow.git
cd mac-keyglow
make app
open KeyGlow.app
```

Install into `/Applications`:
```bash
make install-app
```

Install the `keyglow` CLI tool into `/usr/local/bin`:
```bash
make install
```

---

## 💻 Command-Line Usage (CLI)

```bash
# Status & Brightness
keyglow status                  # Check hardware status and current brightness
keyglow get                     # Output current brightness (0.00 to 1.00)
keyglow set 80%                 # Set brightness (supports percentage or decimal 0.8)
keyglow max                     # Set to 100% maximum brightness
keyglow off                     # Turn backlight off

# Animations
keyglow strike -d 5             # Instant strike: flash on press, zero on release
keyglow candle -d 10            # Warm organic candle flame micro-flicker
keyglow breathe 16 -d 10        # Sinusoidal breathing pulse at 16 BPM
keyglow disco 140 -d 3          # Fast strobe (ideal for build alerts!)
keyglow heartbeat 72            # Dual-peak cardiac heartbeat
keyglow wave 24                 # Harmonic light swell
keyglow typing                  # Reactive typing glow (lights up when typing)
keyglow morse "SOS" -d 10       # Transmit optical Morse code
```

---

## 🔬 Architecture & Hardware Abstraction

KeyGlow uses dynamic Objective-C runtime reflection (`dlopen`, `dlsym`) to interface directly with macOS private frameworks:

* **`CoreBrightness.framework` (`KeyboardBrightnessClient`)**: Direct hardware PWM control without needing private headers or entitlements.
* **`MultitouchSupport.framework` (`MTDeviceRegisterContactFrameCallback`)**: Low-level trackpad contact and Force Touch pressure sensing.
* **`AppKit` (`NSStatusItem`, `NSMenu`, `NSPanel`)**: Pure native macOS UI components consuming < 8MB RAM.

---

## 🔒 Privacy & Security

* **Zero Network Access**: No sockets, no telemetry, no tracking.
* **Zero sudo/root**: Runs strictly as an unprivileged user-space tool.
* **Safe Cleanup**: Original hardware backlight state is saved and restored upon exit.

---

## 📄 License

Released under the [MIT License](LICENSE).
