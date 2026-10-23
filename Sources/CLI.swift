//
//  CLI.swift
//  KeyGlow
//
//  Command-line interface handler for terminal power users and automation scripts.
//

import Foundation

public enum CLIHandler {
    public static func handleArguments(_ args: [String]) -> Bool {
        let arguments = Array(args.dropFirst())
        if arguments.isEmpty || arguments.contains("--menu") || arguments.contains("-m") {
            return false // Run Menu Bar GUI app
        }

        let cmd = arguments[0].lowercased()

        switch cmd {
        case "--help", "-h", "help":
            printUsage()
            return true

        case "--version", "-v", "version":
            print("KeyGlow v1.0.0 — Native macOS Keyboard Backlight & Animation Studio")
            return true

        case "status":
            showStatus()
            return true

        case "get":
            let b = BacklightManager.shared.getBrightness()
            print(String(format: "%.2f", b))
            return true

        case "set":
            if arguments.count < 2 {
                print("Error: Missing brightness value (0.0 to 1.0 or 0% to 100%)")
                print("Example: keyglow set 0.5  or  keyglow set 80%")
                return true
            }
            let raw = arguments[1].replacingOccurrences(of: "%", with: "")
            if let val = Float(raw) {
                let clamped = val > 1.0 ? min(1.0, max(0.0, val / 100.0)) : min(1.0, max(0.0, val))
                let success = BacklightManager.shared.setBrightness(clamped)
                if success {
                    print("Set keyboard brightness to \(Int(clamped * 100))%")
                } else {
                    print("Failed to set brightness. Ensure your Mac model has a supported backlit keyboard.")
                }
            } else {
                print("Error: Invalid brightness value '\(arguments[1])'")
            }
            return true

        case "off":
            _ = BacklightManager.shared.setBrightness(0.0)
            print("Keyboard backlight turned off")
            return true

        case "max":
            _ = BacklightManager.shared.setBrightness(1.0)
            print("Keyboard backlight set to 100%")
            return true

        case "breathe", "breathing":
            var bpm = 16.0
            if arguments.count >= 2, let parsed = Double(arguments[1]) {
                bpm = parsed
            }
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .breathing, bpm: bpm, duration: duration, label: "Breathing (\(Int(bpm)) BPM)")
            return true

        case "heartbeat":
            var bpm = 72.0
            if arguments.count >= 2, let parsed = Double(arguments[1]) {
                bpm = parsed
            }
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .heartbeat, bpm: bpm, duration: duration, label: "Heartbeat Pulse (\(Int(bpm)) BPM)")
            return true

        case "wave":
            var bpm = 24.0
            if arguments.count >= 2, let parsed = Double(arguments[1]) {
                bpm = parsed
            }
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .wave, bpm: bpm, duration: duration, label: "Harmonic Wave (\(Int(bpm)) BPM)")
            return true

        case "strike", "instant", "flash":
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .instantStrike, bpm: 16.0, duration: duration, label: "Instant Strike (Flash to max on keypress, zero on release)")
            return true

        case "candle", "flame", "flicker":
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .candleFlicker, bpm: 30.0, duration: duration, label: "Candle Flame Ambient Micro-Flicker")
            return true

        case "morse":
            var filtered = arguments.dropFirst().filter { $0 != "-d" && $0 != "--duration" }
            let duration = extractDuration(from: arguments)
            if let dur = duration {
                filtered = filtered.filter { $0 != String(dur) && $0 != String(Int(dur)) }
            }
            let message = !filtered.isEmpty ? filtered.joined(separator: " ") : "SOS"
            runMorseLoop(message: message, duration: duration)
            return true

        default:
            print("Unknown command '\(arguments[0])'")
            printUsage()
            return true
        }
    }

    private static func extractDuration(from args: [String]) -> Double? {
        if let idx = args.firstIndex(where: { $0 == "-d" || $0 == "--duration" }), idx + 1 < args.count {
            return Double(args[idx + 1])
        }
        return nil
    }

    private static func showStatus() {
        let isSupported = BacklightManager.shared.isSupported
        let current = BacklightManager.shared.getBrightness()
        let slideEnabled = TrackpadController.shared.isSlideEnabled

        print("======================================================")
        print("KeyGlow Status")
        print("======================================================")
        print("Hardware Supported : \(isSupported ? "Yes (CoreBrightness client connected)" : "No")")
        print("Current Brightness : \(Int(round(current * 100)))% (\(String(format: "%.2f", current)))")
        print("Active Animation   : \(AnimationEngine.shared.activeMode.rawValue)")
        print("Trackpad Slide     : \(slideEnabled ? "Enabled (Cmd + Horizontal Slide)" : "Disabled")")
        print("======================================================")
    }

    private static func runAnimationLoop(mode: GlowMode, bpm: Double, duration: Double?, label: String) {
        AnimationEngine.shared.bpm = bpm
        AnimationEngine.shared.setMode(mode)
        print("Running KeyGlow [\(label)]")
        print("Press Ctrl+C to stop and restore baseline brightness...")

        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler {
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            print("\nStopped KeyGlow. Keyboard restored.")
            exit(0)
        }
        sigint.resume()

        if let d = duration, d > 0 {
            print("Auto-stopping after \(d)s and restoring brightness...")
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                AnimationEngine.shared.stop()
                BacklightManager.shared.restoreOriginalBrightness()
                print("\nCompleted \(label). Keyboard restored.")
                exit(0)
            }
        }

        dispatchMain()
    }

    private static func runMorseLoop(message: String, duration: Double?) {
        AnimationEngine.shared.morseMessage = message
        AnimationEngine.shared.setMode(.morse)
        print("Flashing Morse Code: '\(message)'")
        print("Press Ctrl+C to stop and restore baseline brightness...")

        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler {
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            print("\nStopped KeyGlow. Keyboard restored.")
            exit(0)
        }
        sigint.resume()

        if let d = duration, d > 0 {
            print("Auto-stopping after \(d)s and restoring brightness...")
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                AnimationEngine.shared.stop()
                BacklightManager.shared.restoreOriginalBrightness()
                print("\nCompleted Morse Flash. Keyboard restored.")
                exit(0)
            }
        }

        dispatchMain()
    }

    private static func printUsage() {
        print("""
Usage: keyglow [command] [options]

Commands:
  (no args)             Launch Menu Bar status item application
  --menu, -m            Launch Menu Bar status item application
  status                Show hardware backlight connection status and current level
  get                   Print current brightness as float (0.00 to 1.00)
  set <val>             Set brightness (e.g. 0.5, 75%, 1.0)
  off                   Turn keyboard backlight off (0%)
  max                   Set keyboard backlight to maximum (100%)
  strike                Instant Strike: snap to 100% on key press, 0% on release
  breathe [bpm]         Breathing pulse animation (default: 16 BPM)
  candle                Organic warm candle flame micro-flicker
  heartbeat [bpm]       Dual-peak cardiac rhythm animation (default: 72 BPM)
  wave [bpm]            Harmonic oscillating wave animation (default: 24 BPM)
  morse <text>          Transmit text as optical Morse code beacon (default: 'SOS')
  --version, -v         Display KeyGlow version
  --help, -h            Show this help reference

Options:
  -d, --duration <sec>  Run animation for N seconds then auto-restore and exit
""")
    }
}
