//
//  InfoWindow.swift
//  KeyGlow
//
//  Native informational window explaining KeyGlow features, gestures,
//  Force Touch pressure corner zones, and animation guides.
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
        let height: CGFloat = 560

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        w.title = "KeyGlow — How It Works & Gestures Guide"
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
        # KeyGlow ⌨️✨ How It Works & User Guide
        
        Welcome to KeyGlow — the ultra-lightweight, zero-dependency native keyboard backlight controller and animation studio for macOS.
        
        ---
        
        ## 🔌 1. ⌘ Command + Trackpad Sliding
        
        Adjust your MacBook keyboard brightness at any time without opening Settings or menus:
        
        * **Hold Command (⌘) or Fn (Globe)** + Slide 1 finger horizontally across trackpad.
        * **Slide Left → Right**: Increase keyboard backlight.
        * **Slide Right → Left**: Decrease keyboard backlight.
        * **Visual Bezel (HUD)**: A sleek on-screen display immediately appears showing the current brightness level.
        * **Normal Gestures**: 2, 3, and 4 finger gestures (scrolling, Mission Control) remain 100% untouched.
        
        ---
        
        ## 👆 2. 4-Corner Force Touch Pressure Zones
        
        MacBook Force Touch trackpads measure real-time finger pressure across 4 designated corner zones:
        
        * 🎯 **Top-Left Corner**: Quick Mute / Restore (Tap hard to turn backlight off or restore previous brightness).
        * 🔥 **Top-Right Corner**: Force Turbo Boost (Ramps brightness to 100% proportionally to applied pressure; releasing restores baseline).
        * 🎛️ **Bottom-Left Corner**: Cycle Animation Mode (Deep press cycles to the next animation mode).
        * ⚡ **Bottom-Right Corner**: Strobe Burst (Triggers a quick high-energy strobe burst while held).
        * **Live Pressure Gauge**: The on-screen HUD displays a real-time Force meter (0% to 100%) indicating contact pressure.
        * **Customization**: Every corner action can be customized or disabled directly in the Menu Bar submenu!
        
        ---
        
        ## ✨ 3. Animation Modes
        
        * ⚡ **Instant Strike (Flash on Press)**: When any key or click is pressed, brightness instantly flashes to 100%; upon release, it drops back to 0% super-fast!
        * 🫁 **Breathing Glow**: Smooth sinusoidal pulse inspired by Apple unibody sleep indicators.
        * 🕯️ **Candle Flame**: Organic micro-flickering ambient glow.
        * 💓 **Heartbeat Pulse**: Dual-peak cardiac rhythm simulation (systole and diastole).
        * 🌊 **Harmonic Wave**: Multi-frequency compound sinusoidal light swells.
        * ✨ **Disco Strobe**: High-energy rhythmic strobe flashing.
        * 📡 **Optical Morse Code**: Encodes text messages into blinking optical pulses.
        * ⌨️ **Reactive Typing Glow**: Illuminates keyboard while typing and gently fades when idle.
        
        ---
        
        ## 🔒 4. Architecture, Privacy & Safety
        
        * **Zero External Dependencies**: Pure Swift with direct dynamic binding to CoreBrightness and MultitouchSupport.
        * **No Root / sudo**: Runs entirely within user permissions.
        * **Safe Restoration**: System termination traps guarantee your original backlight brightness is restored when exiting.
        * **Zero Telemetry**: 100% offline with zero network requests.
        """

        textView.string = content.replacingOccurrences(of: "        ", with: "")
        scrollView.documentView = textView
        w.contentView = scrollView

        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
