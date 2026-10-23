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

        case "disco", "strobe":
            var bpm = 120.0
            if arguments.count >= 2, let parsed = Double(arguments[1]) {
                bpm = parsed
            }
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .disco, bpm: bpm, duration: duration, label: "Disco Strobe (\(Int(bpm)) BPM)")
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

        case "typing", "typingglow":
            let duration = extractDuration(from: arguments)
            runAnimationLoop(mode: .typingGlow, bpm: 16.0, duration: duration, label: "Reactive Typing Glow")
            return true

        case "morse":
            var filtered = arguments.dropFirst().filter { $0 != "-d" && $0 != "--duration" }
            let duration = extractDuration(from: arguments)
            if let dur = duration {
                filtered = filtered.filter { $0 != String(dur) && $0 != String(Int(dur)) }
            }
            let message = !filtered.isEmpty ? filtered.joined(separator: " ") : "SOS"
            AnimationEngine.shared.morseMessage = message
            runAnimationLoop(mode: .morse, bpm: 16.0, duration: duration, label: "Morse Code Transmission: \"\(message)\"")
            return true

        default:
            print("Unknown command: '\(cmd)'. Use 'keyglow --help' for available commands.")
            return true
        }
    }

    private static func extractDuration(from arguments: [String]) -> Double? {
        if let idx = arguments.firstIndex(where: { $0 == "--duration" || $0 == "-d" }), idx + 1 < arguments.count {
            return Double(arguments[idx + 1])
        }
        return nil
    }

    private static func showStatus() {
        let isSupported = BacklightManager.shared.isSupported
        let brightness = BacklightManager.shared.getBrightness()
        let kbID = BacklightManager.shared.keyboardID

        print("=== KeyGlow Status ===")
        print("Hardware Supported : \(isSupported ? "Yes (Active)" : "No")")
        print("Keyboard Device ID : \(kbID)")
        print(String(format: "Current Brightness : %.0f%% (raw: %.3f)", brightness * 100, brightness))
        #if arch(arm64)
        print("Architecture        : Apple Silicon")
        #else
        print("Architecture        : Intel x86_64")
        #endif
    }

    private static func runAnimationLoop(mode: GlowMode, bpm: Double, duration: Double?, label: String) {
        guard BacklightManager.shared.isSupported else {
            print("Error: No supported built-in keyboard backlight detected on this Mac.")
            exit(1)
        }

        print("Running KeyGlow [\(label)]")
        if let d = duration {
            print("Auto-stopping after \(d)s and restoring brightness...\n")
        } else {
            print("Press Ctrl+C to stop and restore original brightness.\n")
        }

        AnimationEngine.shared.bpm = bpm
        AnimationEngine.shared.setMode(mode)

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler {
            print("\nStopping animation and restoring keyboard brightness...")
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigint.resume()

        let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigterm.setEventHandler {
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigterm.resume()

        if let d = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                AnimationEngine.shared.stop()
                BacklightManager.shared.restoreOriginalBrightness()
                print("Completed \(label). Keyboard restored.")
                exit(0)
            }
        }

        RunLoop.main.run()
    }

    private static func printUsage() {
        print("""
        KeyGlow — Native macOS Keyboard Backlight & Animation Studio
        
        USAGE:
          keyglow                          Launch native Menu Bar status item app
          keyglow status                   Display keyboard backlight hardware info & brightness
          keyglow get                      Print current brightness value (0.00 - 1.00)
          keyglow set <val>                Set brightness (e.g. '0.75' or '75%')
          keyglow off                      Turn keyboard backlight completely off
          keyglow max                      Set keyboard backlight to 100%
          keyglow breathe [bpm] [-d <sec>] Run smooth sinusoidal breathing glow (default: 16 BPM)
          keyglow disco [bpm] [-d <sec>]   Run high-energy disco strobe effect (default: 120 BPM)
          keyglow heartbeat [bpm] [-d <s]> Run dual-peak cardiac pulse animation (default: 72 BPM)
          keyglow wave [bpm] [-d <sec>]    Run multi-harmonic light wave animation (default: 24 BPM)
          keyglow strike [-d <sec>]        Super-fast strike (flash to max on press, instant zero on release)
          keyglow candle [-d <sec>]        Warm organic candle flame micro-flicker
          keyglow typing [-d <sec>]        Illuminate keyboard dynamically while typing
          keyglow morse <msg> [-d <sec>]   Transmit message in optical Morse code (default: SOS)
          keyglow --help                   Show this help manual
          keyglow --version                Print version information
        
        EXAMPLES:
          keyglow set 50%
          keyglow breathe 14
          keyglow disco 130 -d 3           # Strobe for 3 seconds on command or build notification!
          keyglow morse "SOS" -d 10
        """)
    }
}
