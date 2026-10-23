//
//  InfoWindow.swift
//  KeyGlow
//
//  Native informational window explaining KeyGlow features, gestures,
//  and animation guides.
//

import Cocoa

public final class InfoWindow: NSObject {
    public static let shared = InfoWindow()

    private var window: NSWindow?

    public func show() {
        DispatchQueue.main.async {
            if let w = self.window {
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }

            self.createAndShowWindow()
        }
    }

    private func createAndShowWindow() {
        let width: CGFloat = 520
        let height: CGFloat = 500

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        w.title = "KeyGlow — User Guide & Gestures Reference"
        w.center()
        w.isReleasedWhenClosed = false

        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: width - 20, height: height))
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 24, height: 24)
        textView.backgroundColor = .windowBackgroundColor

        let content = """
        KeyGlow User Guide & Reference
        
        KeyGlow provides native, hardware-level control and lighting effects for MacBook keyboard backlights and trackpads.
        
        ------------------------------------------------------------
        
        1. Command + Trackpad Sliding
        
        Adjust keyboard backlight brightness at any time without opening System Settings or menus:
        
        • Hold Command (⌘) or Fn (Globe) + Slide horizontally across the trackpad.
        • Slide Left to Right: Increase backlight level.
        • Slide Right to Left: Decrease backlight level.
        • Floating HUD Bezel: A native on-screen bezel immediately appears showing the exact brightness percentage.
        • System Gestures Intact: Standard macOS 2, 3, and 4-finger gestures (Mission Control, Spaces, App Exposé) remain completely unaffected.
        
        ------------------------------------------------------------
        
        2. Lighting Effects & Instant Strike
        
        KeyGlow includes 6 native hardware animation modes with configurable peak intensity (up to 100%):
        
        • Instant Strike: Snaps brightness instantly to 100% on any key press or click, snapping immediately to 0% on release.
        • Breathing Glow: Smooth sinusoidal breathing curve inspired by classic Apple sleep indicators.
        • Candle Flame Flicker: Warm, organic micro-flickering ambient illumination.
        • Heartbeat Pulse: Realistic dual-peak cardiac rhythm simulation.
        • Harmonic Wave: Multi-frequency compound sinusoidal light swells.
        • Morse Code Beacon: Encodes and flashes optical Morse code beacons (SOS, custom text).
        
        ------------------------------------------------------------
        
        3. Status Bar Controls & Settings
        
        • Use the unclipped Control Center slider or Presets submenu to set exact brightness levels.
        • Configure Peak Brightness (up to 100%) and Tempo (BPM) in Animation Settings.
        • Command-line interface available: run 'keyglow --help' in Terminal for automation and scripting.
        """

        textView.string = content
        scrollView.documentView = textView
        w.contentView = scrollView

        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
