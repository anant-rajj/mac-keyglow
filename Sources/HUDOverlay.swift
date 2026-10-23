//
//  HUDOverlay.swift
//  KeyGlow
//
//  Native macOS on-screen display (OSD / HUD) for brightness sliding
//  and Force Touch corner pressure sensing feedback.
//

import Cocoa

public final class HUDOverlay: NSObject {
    public static let shared = HUDOverlay()

    private var panel: NSPanel?
    private var iconView: NSImageView?
    private var titleLabel: NSTextField?
    private var valueLabel: NSTextField?
    private var progressBar: NSProgressIndicator?
    private var detailLabel: NSTextField?
    private var pressureBar: NSProgressIndicator?
    private var dismissTimer: Timer?

    private override init() {
        super.init()
        DispatchQueue.main.async {
            self.setupPanel()
        }
    }

    private func setupPanel() {
        let width: CGFloat = 240
        let height: CGFloat = 170

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        p.isOpaque = false
        p.backgroundColor = .clear
        p.level = .floating
        p.ignoresMouseEvents = true
        p.hasShadow = true
        p.isReleasedWhenClosed = false

        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 20
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderWidth = 1
        visualEffect.layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor

        // Icon
        let icon = NSImageView(frame: NSRect(x: (width - 44) / 2, y: height - 56, width: 44, height: 44))
        icon.image = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: "Keyboard")
        icon.contentTintColor = .labelColor
        visualEffect.addSubview(icon)
        self.iconView = icon

        // Title
        let title = NSTextField(labelWithString: "Keyboard Brightness")
        title.frame = NSRect(x: 10, y: height - 80, width: width - 20, height: 18)
        title.alignment = .center
        title.font = .systemFont(ofSize: 13, weight: .semibold)
        title.textColor = .labelColor
        visualEffect.addSubview(title)
        self.titleLabel = title

        // Progress Bar
        let progress = NSProgressIndicator(frame: NSRect(x: 24, y: height - 104, width: width - 48, height: 10))
        progress.isIndeterminate = false
        progress.minValue = 0.0
        progress.maxValue = 100.0
        progress.doubleValue = 50.0
        visualEffect.addSubview(progress)
        self.progressBar = progress

        // Value text (e.g. "75%")
        let val = NSTextField(labelWithString: "50%")
        val.frame = NSRect(x: 10, y: height - 124, width: width - 20, height: 16)
        val.alignment = .center
        val.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        val.textColor = .secondaryLabelColor
        visualEffect.addSubview(val)
        self.valueLabel = val

        // Detail label for Pressure sensing
        let detail = NSTextField(labelWithString: "")
        detail.frame = NSRect(x: 10, y: 12, width: width - 20, height: 16)
        detail.alignment = .center
        detail.font = .systemFont(ofSize: 11, weight: .regular)
        detail.textColor = .tertiaryLabelColor
        visualEffect.addSubview(detail)
        self.detailLabel = detail

        p.contentView = visualEffect
        self.panel = p
    }

    public func showBrightness(_ brightness: Float, source: String = "Trackpad Slide") {
        DispatchQueue.main.async {
            guard self.panel != nil else { return }
            let percent = Int(round(brightness * 100))

            self.titleLabel?.stringValue = "Keyboard Brightness"
            self.iconView?.image = NSImage(systemSymbolName: brightness > 0 ? "keyboard.fill" : "keyboard", accessibilityDescription: "Brightness")
            self.progressBar?.doubleValue = Double(percent)
            self.valueLabel?.stringValue = "\(percent)%"
            self.detailLabel?.stringValue = source

            self.present()
        }
    }

    public func showPressure(corner: String, pressure: Float, action: String) {
        DispatchQueue.main.async {
            guard self.panel != nil else { return }
            let percent = Int(round(pressure * 100))

            self.titleLabel?.stringValue = corner
            self.iconView?.image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Pressure")
            self.progressBar?.doubleValue = Double(percent)
            self.valueLabel?.stringValue = "Force: \(percent)%"
            self.detailLabel?.stringValue = action

            self.present()
        }
    }

    private func present() {
        guard let p = panel else { return }

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = p.frame
            let x = screenFrame.midX - (panelFrame.width / 2)
            let y = screenFrame.minY + 120 // Lower center of screen, above Dock
            p.setFrameOrigin(NSPoint(x: x, y: y))
        }

        p.alphaValue = 1.0
        p.orderFrontRegardless()

        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.35
                self?.panel?.animator().alphaValue = 0.0
            } completionHandler: {
                self?.panel?.orderOut(nil)
            }
        }
    }
}
