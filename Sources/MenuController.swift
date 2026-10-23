//
//  MenuController.swift
//  KeyGlow
//
//  Native macOS Status Bar Menu Controller.
//  Refined macOS Control Center aesthetic, SF Symbols outline icons, and unclipped slider.
//

import Cocoa

public final class MenuController: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var mainMenu: NSMenu?
    private var slider: NSSlider?
    private var percentLabel: NSTextField?
    private var modeMenuItems: [GlowMode: NSMenuItem] = [:]
    private var statusHeaderItem: NSMenuItem?
    private var slideToggleItem: NSMenuItem?
    private var cornerToggleItem: NSMenuItem?
    private var peakMenuItems: [Float: NSMenuItem] = [:]
    private var sigintSource: DispatchSourceSignal?
    private var sigtermSource: DispatchSourceSignal?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupSignalTraps()
        setupStatusItem()
        TrackpadController.shared.start()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        TrackpadController.shared.stop()
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
            button.title = "KeyGlow"
        }
        button.toolTip = "KeyGlow — Keyboard Backlight Studio & Gestures"

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

    private func makeSymbolImage(_ name: String, pointSize: CGFloat = 12, weight: NSFont.Weight = .regular) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let sym = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }
        sym.isTemplate = true
        return sym
    }

    private func rebuildMenu() {
        guard let menu = mainMenu else { return }
        menu.removeAllItems()
        modeMenuItems.removeAll()
        peakMenuItems.removeAll()

        // 1. App Title & Status Header
        let isSupported = BacklightManager.shared.isSupported
        let titleItem = NSMenuItem(title: "KeyGlow Studio", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        titleItem.image = makeSymbolImage("keyboard", pointSize: 13, weight: .semibold)
        let titleFont = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleItem.attributedTitle = NSAttributedString(
            string: "KeyGlow Studio",
            attributes: [.font: titleFont, .foregroundColor: NSColor.labelColor]
        )
        menu.addItem(titleItem)

        let statusText = isSupported ? "Hardware: Connected" : "Hardware: No Backlight Detected"
        let statusItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        let statusFont = NSFont.systemFont(ofSize: 10, weight: .medium)
        let statusColor = isSupported ? NSColor.systemGreen : NSColor.systemRed
        statusItem.image = makeSymbolImage(isSupported ? "circle.fill" : "exclamationmark.circle", pointSize: 8)
        statusItem.attributedTitle = NSAttributedString(
            string: statusText,
            attributes: [.font: statusFont, .foregroundColor: statusColor]
        )
        menu.addItem(statusItem)
        self.statusHeaderItem = statusItem

        // Information Guide button
        let infoItem = NSMenuItem(title: "How KeyGlow Works...", action: #selector(showInfoClicked), keyEquivalent: "i")
        infoItem.target = self
        infoItem.image = makeSymbolImage("info.circle", pointSize: 12)
        menu.addItem(infoItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Interactive Brightness Slider (macOS Control Center Styled, Unclipped)
        let sliderItem = NSMenuItem()
        let viewWidth: CGFloat = 260
        let viewHeight: CGFloat = 62
        let sliderView = NSView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight))

        // Top label row
        let curVal = BacklightManager.shared.getBrightness()
        let titleLabel = NSTextField(labelWithString: "Keyboard Brightness")
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        titleLabel.frame = NSRect(x: 18, y: 38, width: 140, height: 16)
        sliderView.addSubview(titleLabel)

        let pLabel = NSTextField(labelWithString: "\(Int(round(curVal * 100)))%")
        pLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .semibold)
        pLabel.textColor = NSColor.secondaryLabelColor
        pLabel.alignment = .right
        pLabel.frame = NSRect(x: 180, y: 38, width: 62, height: 16)
        sliderView.addSubview(pLabel)
        self.percentLabel = pLabel

        // Flanker icons (sun.min on left, sun.max on right)
        let minIcon = NSImageView(frame: NSRect(x: 16, y: 12, width: 16, height: 16))
        minIcon.image = makeSymbolImage("sun.min", pointSize: 11, weight: .regular)
        minIcon.contentTintColor = NSColor.secondaryLabelColor
        sliderView.addSubview(minIcon)

        let maxIcon = NSImageView(frame: NSRect(x: viewWidth - 32, y: 12, width: 16, height: 16))
        maxIcon.image = makeSymbolImage("sun.max", pointSize: 11, weight: .regular)
        maxIcon.contentTintColor = NSColor.secondaryLabelColor
        sliderView.addSubview(maxIcon)

        // Unclipped NSSlider centered between flanker icons
        // Generous 26pt height guarantees the 20pt circular knob is completely unclipped
        let s = NSSlider(value: Double(curVal), minValue: 0.0, maxValue: 1.0, target: self, action: #selector(sliderMoved(_:)))
        s.frame = NSRect(x: 36, y: 7, width: viewWidth - 72, height: 26)
        s.controlSize = .regular
        s.isContinuous = true
        sliderView.addSubview(s)
        self.slider = s

        sliderItem.view = sliderView
        menu.addItem(sliderItem)

        // Quick Presets Submenu
        let presetsSubmenu = NSMenu()
        let presetsItem = NSMenuItem(title: "Presets", action: nil, keyEquivalent: "")
        presetsItem.image = makeSymbolImage("slider.horizontal.below.rectangle", pointSize: 12)
        presetsItem.submenu = presetsSubmenu
        for (name, val) in [("Off (0%)", 0.0), ("Dim (20%)", 0.2), ("Medium (50%)", 0.5), ("Bright (80%)", 0.8), ("Max (100%)", 1.0)] {
            let item = NSMenuItem(title: name, action: #selector(presetClicked(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = val
            presetsSubmenu.addItem(item)
        }
        menu.addItem(presetsItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Trackpad & Gestures Controls
        let gesturesHeader = NSMenuItem(title: "TRACKPAD GESTURES", action: nil, keyEquivalent: "")
        gesturesHeader.isEnabled = false
        gesturesHeader.attributedTitle = NSAttributedString(
            string: "TRACKPAD GESTURES",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(gesturesHeader)

        let slideItem = NSMenuItem(title: "Command + Trackpad Slide", action: #selector(toggleTrackpadSlide), keyEquivalent: "")
        slideItem.target = self
        slideItem.image = makeSymbolImage("hand.draw", pointSize: 12)
        slideItem.state = TrackpadController.shared.isSlideEnabled ? .on : .off
        menu.addItem(slideItem)
        self.slideToggleItem = slideItem

        let cornerItem = NSMenuItem(title: "4-Corner Pressure Actions", action: #selector(toggleCornerPressure), keyEquivalent: "")
        cornerItem.target = self
        cornerItem.image = makeSymbolImage("hand.tap", pointSize: 12)
        cornerItem.state = TrackpadController.shared.isCornersEnabled ? .on : .off
        menu.addItem(cornerItem)
        self.cornerToggleItem = cornerItem

        let cornersSubmenu = NSMenu()
        let cornersMenuItem = NSMenuItem(title: "Configure Pressure Corners...", action: nil, keyEquivalent: "")
        cornersMenuItem.image = makeSymbolImage("slider.horizontal.2", pointSize: 12)
        cornersMenuItem.submenu = cornersSubmenu

        addCornerActionSubmenu(to: cornersSubmenu, title: "Top-Left Corner", iconName: "arrow.up.left", current: TrackpadController.shared.topLeftAction, selector: #selector(topLeftActionSelected(_:)))
        addCornerActionSubmenu(to: cornersSubmenu, title: "Top-Right Corner", iconName: "arrow.up.right", current: TrackpadController.shared.topRightAction, selector: #selector(topRightActionSelected(_:)))
        addCornerActionSubmenu(to: cornersSubmenu, title: "Bottom-Left Corner", iconName: "arrow.down.left", current: TrackpadController.shared.bottomLeftAction, selector: #selector(bottomLeftActionSelected(_:)))
        addCornerActionSubmenu(to: cornersSubmenu, title: "Bottom-Right Corner", iconName: "arrow.down.right", current: TrackpadController.shared.bottomRightAction, selector: #selector(bottomRightActionSelected(_:)))
        menu.addItem(cornersMenuItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Effects & Animations
        let effectsHeader = NSMenuItem(title: "LIGHTING EFFECTS", action: nil, keyEquivalent: "")
        effectsHeader.isEnabled = false
        effectsHeader.attributedTitle = NSAttributedString(
            string: "LIGHTING EFFECTS",
            attributes: [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        menu.addItem(effectsHeader)

        for mode in GlowMode.allCases {
            let item = NSMenuItem(title: mode.title, action: #selector(modeSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            item.image = makeSymbolImage(mode.systemSymbolName, pointSize: 12)
            modeMenuItems[mode] = item
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        // 5. Animation Parameters Configuration
        let configItem = NSMenuItem(title: "Animation Settings", action: nil, keyEquivalent: "")
        configItem.image = makeSymbolImage("gearshape", pointSize: 12)
        let configSubmenu = NSMenu()
        configItem.submenu = configSubmenu

        let peakItem = NSMenuItem(title: "Peak Brightness", action: nil, keyEquivalent: "")
        peakItem.image = makeSymbolImage("sun.max", pointSize: 12)
        let peakSubmenu = NSMenu()
        peakItem.submenu = peakSubmenu
        for (label, peak) in [("100% (Maximum / Full)", 1.0), ("85%", 0.85), ("70%", 0.70), ("50%", 0.50)] {
            let item = NSMenuItem(title: label, action: #selector(peakSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = Float(peak)
            peakMenuItems[Float(peak)] = item
            peakSubmenu.addItem(item)
        }
        configSubmenu.addItem(peakItem)

        let speedItem = NSMenuItem(title: "Tempo (BPM)", action: nil, keyEquivalent: "")
        speedItem.image = makeSymbolImage("speedometer", pointSize: 12)
        let speedSubmenu = NSMenu()
        speedItem.submenu = speedSubmenu
        for bpmVal in [10.0, 16.0, 24.0, 40.0, 60.0, 90.0, 120.0] {
            let item = NSMenuItem(title: "\(Int(bpmVal)) BPM", action: #selector(bpmSelected(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = bpmVal
            speedSubmenu.addItem(item)
        }
        configSubmenu.addItem(speedItem)

        let morseSub = NSMenuItem(title: "Morse Beacon Message", action: nil, keyEquivalent: "")
        morseSub.image = makeSymbolImage("text.bubble", pointSize: 12)
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

        // 6. Actions: Reset & Quit
        let resetItem = NSMenuItem(title: "Reset to Default", action: #selector(resetClicked), keyEquivalent: "r")
        resetItem.target = self
        resetItem.image = makeSymbolImage("arrow.counterclockwise", pointSize: 12)
        menu.addItem(resetItem)

        let quitItem = NSMenuItem(title: "Quit KeyGlow", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = makeSymbolImage("power", pointSize: 12)
        menu.addItem(quitItem)
    }

    private func addCornerActionSubmenu(to parent: NSMenu, title: String, iconName: String, current: CornerAction, selector: Selector) {
        let menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        menuItem.image = makeSymbolImage(iconName, pointSize: 12)
        let sub = NSMenu()
        menuItem.submenu = sub

        for act in CornerAction.allCases {
            let item = NSMenuItem(title: act.rawValue, action: selector, keyEquivalent: "")
            item.target = self
            item.representedObject = act
            item.state = (act == current) ? .on : .off
            sub.addItem(item)
        }
        parent.addItem(menuItem)
    }

    private func updateMenuState() {
        let current = BacklightManager.shared.getBrightness()
        slider?.doubleValue = Double(current)
        percentLabel?.stringValue = "\(Int(round(current * 100)))%"

        let activeMode = AnimationEngine.shared.activeMode
        for (mode, item) in modeMenuItems {
            item.state = (mode == activeMode) ? .on : .off
        }

        slideToggleItem?.state = TrackpadController.shared.isSlideEnabled ? .on : .off
        cornerToggleItem?.state = TrackpadController.shared.isCornersEnabled ? .on : .off

        let curMax = AnimationEngine.shared.maxIntensity
        for (peakVal, item) in peakMenuItems {
            item.state = (abs(peakVal - curMax) < 0.05) ? .on : .off
        }
    }

    @objc private func showInfoClicked() {
        InfoWindow.shared.show()
    }

    @objc private func toggleTrackpadSlide() {
        TrackpadController.shared.isSlideEnabled.toggle()
        updateMenuState()
    }

    @objc private func toggleCornerPressure() {
        TrackpadController.shared.isCornersEnabled.toggle()
        updateMenuState()
    }

    @objc private func topLeftActionSelected(_ sender: NSMenuItem) {
        if let act = sender.representedObject as? CornerAction {
            TrackpadController.shared.topLeftAction = act
            rebuildMenu()
        }
    }

    @objc private func topRightActionSelected(_ sender: NSMenuItem) {
        if let act = sender.representedObject as? CornerAction {
            TrackpadController.shared.topRightAction = act
            rebuildMenu()
        }
    }

    @objc private func bottomLeftActionSelected(_ sender: NSMenuItem) {
        if let act = sender.representedObject as? CornerAction {
            TrackpadController.shared.bottomLeftAction = act
            rebuildMenu()
        }
    }

    @objc private func bottomRightActionSelected(_ sender: NSMenuItem) {
        if let act = sender.representedObject as? CornerAction {
            TrackpadController.shared.bottomRightAction = act
            rebuildMenu()
        }
    }

    @objc private func sliderMoved(_ sender: NSSlider) {
        let val = Float(sender.doubleValue)
        if AnimationEngine.shared.activeMode != .manual {
            AnimationEngine.shared.stop()
            updateMenuState()
        }
        BacklightManager.shared.setBrightness(val)
        percentLabel?.stringValue = "\(Int(round(val * 100)))%"
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
        updateMenuState()
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
        TrackpadController.shared.stop()
        AnimationEngine.shared.stop()
        BacklightManager.shared.restoreOriginalBrightness()
        NSApplication.shared.terminate(nil)
    }

    private func setupSignalTraps() {
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigint.setEventHandler {
            TrackpadController.shared.stop()
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigint.resume()
        self.sigintSource = sigint

        let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigterm.setEventHandler {
            TrackpadController.shared.stop()
            AnimationEngine.shared.stop()
            BacklightManager.shared.restoreOriginalBrightness()
            exit(0)
        }
        sigterm.resume()
        self.sigtermSource = sigterm
    }
}

extension GlowMode {
    public var title: String {
        switch self {
        case .manual: return "Manual"
        case .instantStrike: return "Instant Strike (Press Flash)"
        case .breathing: return "Breathing Glow"
        case .candleFlicker: return "Candle Flame Flicker"
        case .heartbeat: return "Heartbeat Pulse"
        case .wave: return "Harmonic Wave"
        case .disco: return "Disco Strobe"
        case .morse: return "Morse Code Beacon"
        case .typingGlow: return "Reactive Typing Glow"
        }
    }

    public var systemSymbolName: String {
        switch self {
        case .manual: return "slider.horizontal.3"
        case .instantStrike: return "bolt"
        case .breathing: return "wind"
        case .candleFlicker: return "flame"
        case .heartbeat: return "waveform.path.ecg"
        case .wave: return "waveform"
        case .disco: return "sparkles"
        case .morse: return "antenna.radiowaves.left.and.right"
        case .typingGlow: return "keyboard"
        }
    }
}
