# KeyGlow

> **Ultra-lightweight, zero-dependency native macOS Menu Bar controller and animation studio for MacBook keyboard backlights and trackpads.**

KeyGlow provides hardware-level keyboard backlight brightness control, smooth mathematical animations, Command + Trackpad sliding with a floating on-screen HUD bezel, and a refined macOS Control Center-themed Menu Bar interface.

---

## Highlights

- **macOS Control Center Aesthetic**: Native unclipped brightness slider, outline SF Symbols, and zero emojis.
- **Command + Trackpad Slide**: Hold `⌘ Command` (or `Fn`) and slide horizontally on the trackpad to adjust brightness from anywhere, complete with a floating translucent bezel HUD.
- **Instant Strike**: Flashes keyboard brightness to 100% on every key press or mouse click, snapping back to 0% immediately upon release.
- **Mathematical Animation Engine**: 45–60 FPS hardware illumination with < 0.2% CPU overhead and configurable peak brightness up to 100%.
- **Zero External Dependencies**: Pure native Swift using Apple's private `CoreBrightness` and `MultitouchSupport` frameworks.
- **Apple Silicon & Intel Support**: Compatible with M1/M2/M3/M4 and Intel MacBooks on macOS 13+ (Ventura, Sonoma, Sequoia).
- **Dual Interface**: Runs as a lightweight background Menu Bar status item or a versatile CLI utility for automation.

---

## Lighting Effects

| Effect | Description | Ideal For |
| :--- | :--- | :--- |
| **Instant Strike** | Snaps to 100% on key/mouse press, instantly 0% on release | Fast typing flare, visual feedback |
| **Breathing Glow** | Smooth sinusoidal rhythm (classic Apple sleep indicator) | Deep work, focus, calm ambiance |
| **Candle Flame** | Organic warm micro-flickering ambient flame | Evening relaxation, subtle glow |
| **Heartbeat** | Anatomical dual-peak cardiac rhythm | Meditative pacing, chill sessions |
| **Harmonic Wave** | Multi-frequency organic light swell | Ambient illumination |
| **Morse Code** | Optical telegraph beacon for SOS or custom text | Notifications, beacons, signaling |

---

## Gestures & Controls

### Command + Trackpad Slide
- Hold **⌘ Command** (or **Fn**) and slide one finger horizontally across the trackpad.
- Slide **Left → Right**: Increases keyboard brightness.
- Slide **Right → Left**: Decreases keyboard brightness.
- A floating HUD bezel appears in real-time displaying current brightness.

---

## CLI Usage

KeyGlow includes a full command-line interface for terminal workflows:

```bash
# Query status
keyglow status
keyglow get

# Set exact brightness
keyglow set 80%
keyglow set 0.5
keyglow max
keyglow off

# Run animations
keyglow strike
keyglow breathe 20 -d 10
keyglow candle -d 30
keyglow heartbeat 75
keyglow wave 24
keyglow morse "HELLO"
```

---

## Installation & Building

### Build from Source

```bash
git clone https://github.com/anant-rajj/mac-keyglow.git
cd mac-keyglow
make release
make app
make install-app
```

---

## License

Distributed under the MIT License.
