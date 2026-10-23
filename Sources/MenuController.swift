//
//  MenuController.swift
//  KeyGlow
//
//  Native macOS Status Bar Menu Controller.
//  High-performance, pure AppKit implementation with zero dependencies and < 8MB RAM footprint.
//

import Cocoa

public final class MenuController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var mainMenu: NSMenu?
    private var slider: NSSlider?
    private var percentLabel: NSTextField?
    private var modeMenuItems: [GlowMode: NSMenuItem] = [:]
    private var statusHeaderItem: NSMenuItem?
    private var sigintSource: DispatchSourceSignal?
    private var sigtermSource: DispatchSourceSignal?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalTraps()
        setupStatusItem()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        AnimationEngine.shared.stop()
        BacklightManager.shared.restoreOriginalBrightness()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }

        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium)
        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "KeyGlow")?
            .withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "⌨️"
        }
        button.toolTip = "KeyGlow — Keyboard Backlight Studio"

        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        self.mainMenu = menu
        statusItem?.menu = menu

        rebuildMenu()
    }

    public func menuWillOpen(_ menu: NSMenu) {
        updateMenuState()
    }

    private func rebuildMenu() {
        guard let menu = mainMenu else { return }
        menu.removeAllItems()
        modeMenuItems.removeAll()

        // 1. App Title & Status Header
        let isSupported = BacklightManager.shared.isSupported
        let titleItem = NSMenuItem(title: "KeyGlow Studio", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        let font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleItem.attributedTitle = NSAttributedString(
            string: "KeyGlow Studio",
            attributes: [.font: font, .foregroundColor: NSColor.labelColor]
        )
        menu.addItem(titleItem)

        let statusText = isSupported ? "● Hardware: Connected" : "○ Hardware: No Backlight Found"
        let statusItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        let statusFont = NSFont.systemFont(ofSize: 10, weight: .medium)
        let statusColor = isSupported ? NSColor.systemGreen : NSColor.systemRed
        statusItem.attributedTitle = NSAttributedString(
            string: statusText,
            attributes: [.font: statusFont, .foregroundColor: statusColor]
        )
        menu.addItem(statusItem)
        self.statusHeaderItem = statusItem

        menu.addItem(NSMenuItem.separator())

        // 2. Interactive Slider Item
        let sliderItem = NSMenuItem()
        let sliderView = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 42))

        let label = NSTextField(labelWithString: "Brightness")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = NSColor.secondaryLabelColor
        label.frame = NSRect(x: 16, y: 22, width: 80, height: 16)
        sliderView.addSubview(label)

        let curVal = BacklightManager.shared.getBrightness()
        let pLabel = NSTextField(labelWithString: "\(Int(curVal * 100))%")
        pLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        pLabel.alignment = .right
        pLabel.frame = NSRect(x: 140, y: 22, width: 64, height: 16)
        sliderView.addSubview(pLabel)
        self.percentLabel = pLabel

        let s = NSSlider(value: Double(curVal), minValue: 0.0, maxValue: 1.0, target: self, action: #selector(sliderMoved(_:)))
        s.frame = NSRect(x: 14, y: 4, width: 192, height: 18)
        s.isContinuous = true
        sliderView.addSubview(s)
        self.slider = s

        sliderItem.view = sliderView
        menu.addItem(sliderItem)

        // Quick Presets Submenu
        let presetsSubmenu = NSMenu()
        let presetsItem = NSMenuItem(title: "Quick Presets", action: nil, keyEquivalent: "")
        presetsItem.submenu = presetsSubmenu
        for (name, val) in [("Off (0%)", 0.0), ("Dim (20%)", 0.2), ("Medium (50%)", 0.5), ("Bright (80%)", 0.8), ("Max (100%)", 1.0)] {
            let item = NSMenuItem(title: name, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            presetsSubmenu.addItem(item)
        }
        menu.addItem(presetsItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Effects & Animations
        let effectsHeader = NSMenuItem(title: "ANIMATION MODES", action: nil, keyEquivalent: "")
        effectsHeader.isEnabled = false
        effectsHeader.attributedTitle = NSAttributedString(
            string: "ANIMATION MODES",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(effectsHeader)

        for mode in GlowMode.allCases {
            let item = NSMenuItem(title: mode.titleWithEmoji, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            modeMenuItems[mode] = item
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // 4. Animation Parameters Configuration
        let configItem = NSMenuItem(title: "Animation Settings", action: nil, keyEquivalent: "")
        let configSubmenu = NSMenu()
        configItem.submenu = configSubmenu

        // Speed / BPM Submenu
        let speedItem = NSMenuItem(title: "Tempo (BPM)", action: nil, keyEquivalent: "")
        let speedSubmenu = NSMenu()
        speedItem.submenu = speedSubmenu
        for bpmVal in [10.0, 16.0, 24.0, 40.0, 60.0, 90.0, 120.0] {
            let item = NSMenuItem(title: "\(Int(bpmVal)) BPM", action: #selector(bpmSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = bpmVal
            speedSubmenu.addItem(item)
        }
        configSubmenu.addItem(speedItem)

        // Peak Intensity Submenu
        let peakItem = NSMenuItem(title: "Peak Intensity", action: nil, keyEquivalent: "")
        let peakSubmenu = NSMenu()
        peakItem.submenu = peakSubmenu
        for peak in [1.0, 0.85, 0.70, 0.50] {
            let item = NSMenuItem(title: "\(Int(peak * 100))%", action: #selector(peakSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = Float(peak)
            peakSubmenu.addItem(item)
        }
        configSubmenu.addItem(peakItem)

        // Morse message
        let morseSub = NSMenuItem(title: "Morse Beacon Message", action: nil, keyEquivalent: "")
        let morseMenu = NSMenu()
        morseSub.submenu = morseMenu
        for msg in ["SOS", "HELLO", "APPLE", "MAC", "GLOW"] {
            let item = NSMenuItem(title: msg, action: #selector(morseSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = msg
            morseMenu.addItem(item)
        }
        configSubmenu.addItem(morseSub)

        menu.addItem(configItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Actions: Reset & Quit
        let resetItem = NSMenuItem(title: "Reset to Default", action: #selector(resetClicked), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)

        let quitItem = NSMenuItem(title: "Quit KeyGlow", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func updateMenuState() {
        let current = BacklightManager.shared.getBrightness()
        slider?.doubleValue = Double(current)
        percentLabel?.stringValue = "\(Int(current * 100))%"

        let activeMode = AnimationEngine.shared.activeMode
        for (mode, item) in modeMenuItems {
            item.state = (mode == activeMode) ? .on : .off
        }
    }

    @objc private func sliderMoved(_ sender: NSSlider) {
        let val = Float(sender.doubleValue)
        if AnimationEngine.shared.activeMode != .manual {
            AnimationEngine.shared.stop()
            updateMenuState()
        }
        BacklightManager.shared.setBrightness(val)
        percentLabel?.stringValue = "\(Int(val * 100))%"
    }

    @objc private func presetClicked(_ sender: NSMenuItem) {
        guard let val = sender.representedObject as? Double else { return }
        AnimationEngine.shared.stop()
        BacklightManager.shared.setBrightness(Float(val))
        updateMenuState()
    }

    @objc private func modeSelected(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? GlowMode else { return }
        if mode == AnimationEngine.shared.activeMode {
            AnimationEngine.shared.stop()
        } else {
            AnimationEngine.shared.setMode(mode)
        }
        updateMenuState()
    }

    @objc private func bpmSelected(_ sender: NSMenuItem) {
        guard let bpm = sender.representedObject as? Double else { return }
        AnimationEngine.shared.bpm = bpm
        if AnimationEngine.shared.activeMode != .manual {
            AnimationEngine.shared.setMode(AnimationEngine.shared.activeMode)
        }
    }

    @objc private func peakSelected(_ sender: NSMenuItem) {
        guard let peak = sender.representedObject as? Float else { return }
        AnimationEngine.shared.maxIntensity = peak
    }

    @objc private func morseSelected(_ sender: NSMenuItem) {
        guard let msg = sender.representedObject as? String else { return }
        AnimationEngine.shared.morseMessage = msg
        if AnimationEngine.shared.activeMode == .morse {
            AnimationEngine.shared.setMode(.morse)
        }
    }

    @objc private func resetClicked() {
        AnimationEngine.shared.stop()
        BacklightManager.shared.restoreOriginalBrightness()
        updateMenuState()
    }

    @objc private func quitClicked() {
        AnimationEngine.shared.stop()
        BacklightManager.shared.restoreOriginalBrightness()
        NSApplication.shared.terminate(nil)
    }

    private func setupSignalTraps() {
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler {
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigint.resume()
        self.sigintSource = sigint

        let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigterm.setEventHandler {
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigterm.resume()
        self.sigtermSource = sigterm
    }
}

extension GlowMode {
    public var titleWithEmoji: String {
        switch self {
        case .manual: return "Manual (Static Level)"
        case .breathing: return "🫁 Breathing Glow"
        case .disco: return "⚡ Disco Strobe"
        case .heartbeat: return "💓 Heartbeat Pulse"
        case .wave: return "🌊 Harmonic Wave"
        case .morse: return "📡 Morse Code Beacon"
        case .typingGlow: return "⌨️ Reactive Typing Glow"
        }
    }
}
