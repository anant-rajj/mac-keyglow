//
//  TrackpadController.swift
//  KeyGlow
//
//  Hardware interface for MacBook Multitouch Trackpad.
//  Provides Command/Fn + horizontal slide brightness control with native HUD feedback.
//

import Cocoa
import CoreGraphics

// MultitouchSupport C-structs matching macOS private framework ABI
public struct MTPoint {
    public var x: Float
    public var y: Float
}

public struct MTVector {
    public var position: MTPoint
    public var velocity: MTPoint
}

public struct MTTouch {
    public var frame: Int32
    public var timestamp: Double
    public var pathIndex: Int32
    public var state: Int32
    public var fingerID: Int32
    public var handID: Int32
    public var normalized: MTVector
    public var zTotal: Float
    public var field9: Int32
    public var angle: Float
    public var majorAxis: Float
    public var minorAxis: Float
    public var absolute: MTVector
    public var field14: Int32
    public var field15: Int32
    public var zDensity: Float
}

public final class TrackpadController: NSObject {
    public static let shared = TrackpadController()

    public var isSlideEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "KeyGlow_TrackpadSlide") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "KeyGlow_TrackpadSlide") }
    }

    private typealias MTDeviceRef = UnsafeMutableRawPointer
    private typealias MTContactCallback = @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32, Double, Int32) -> Int32
    private typealias MTDeviceCreateListFunc = @convention(c) () -> Unmanaged<CFMutableArray>?
    private typealias MTRegisterCallbackFunc = @convention(c) (UnsafeMutableRawPointer, MTContactCallback) -> Void
    private typealias MTDeviceStartFunc = @convention(c) (UnsafeMutableRawPointer, Int32) -> Void
    private typealias MTDeviceStopFunc = @convention(c) (UnsafeMutableRawPointer, Int32) -> Void

    private var isRunning = false
    private var devices: [MTDeviceRef] = []
    private var trackingFingerID: Int32 = -1
    private var lastX: Float = 0.0

    private override init() {
        super.init()
    }

    public func start() {
        guard !isRunning else { return }

        guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW) else {
            return
        }

        guard let createListSym = dlsym(handle, "MTDeviceCreateList"),
              let registerSym = dlsym(handle, "MTRegisterContactFrameCallback"),
              let startSym = dlsym(handle, "MTDeviceStart") else {
            return
        }

        let createList = unsafeBitCast(createListSym, to: MTDeviceCreateListFunc.self)
        let register = unsafeBitCast(registerSym, to: MTRegisterCallbackFunc.self)
        let startFunc = unsafeBitCast(startSym, to: MTDeviceStartFunc.self)

        guard let devList = createList()?.takeRetainedValue() else { return }
        let count = CFArrayGetCount(devList)
        guard count > 0 else { return }

        let callback: MTContactCallback = { device, touchesPtr, numTouches, timestamp, frame in
            let touches = touchesPtr.assumingMemoryBound(to: MTTouch.self)
            TrackpadController.shared.handleTouches(touches: touches, count: Int(numTouches))
            return 0
        }

        for i in 0..<count {
            let dev = CFArrayGetValueAtIndex(devList, i)
            let devPtr = unsafeBitCast(dev, to: MTDeviceRef.self)
            register(devPtr, callback)
            startFunc(devPtr, 0)
            devices.append(devPtr)
        }

        isRunning = true
    }

    public func stop() {
        guard isRunning else { return }
        guard let handle = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_NOW),
              let stopSym = dlsym(handle, "MTDeviceStop") else { return }
        let stopFunc = unsafeBitCast(stopSym, to: MTDeviceStopFunc.self)
        for dev in devices {
            stopFunc(dev, 0)
        }
        devices.removeAll()
        isRunning = false
    }

    private func isModifierDown() -> Bool {
        let hid = CGEventSource.flagsState(.hidSystemState)
        let session = CGEventSource.flagsState(.combinedSessionState)
        let cmd = hid.contains(.maskCommand) || session.contains(.maskCommand)
        let fn = (hid.rawValue & 0x00800000 != 0) || (session.rawValue & 0x00800000 != 0)
        return cmd || fn
    }

    private func handleTouches(touches: UnsafeMutablePointer<MTTouch>, count: Int) {
        guard count > 0 else {
            resetTracking()
            return
        }

        let t = touches[0]
        let x = t.normalized.position.x // 0.0 (left) to 1.0 (right)
        let y = t.normalized.position.y // 0.0 (bottom) to 1.0 (top)
        let state = t.state
        let fingerID = t.fingerID

        if state == 5 || state >= 6 || state == 0 { // touch ended / out of range
            if fingerID == trackingFingerID {
                resetTracking()
            }
            return
        }

        // Command or Fn + Horizontal Trackpad Slide
        if isSlideEnabled && count == 1 && isModifierDown() {
            handleSlide(x: x, y: y, fingerID: fingerID)
        } else {
            if trackingFingerID != -1 && !isModifierDown() {
                trackingFingerID = -1
            }
        }
    }

    private func handleSlide(x: Float, y: Float, fingerID: Int32) {
        if trackingFingerID == -1 {
            trackingFingerID = fingerID
            lastX = x
            return
        }

        guard fingerID == trackingFingerID else { return }

        let dx = x - lastX
        if abs(dx) >= 0.003 {
            let current = BacklightManager.shared.getBrightness()
            let sensitivity: Float = 2.8
            var target = current + (dx * sensitivity)

            // Edge snapping
            if target <= 0.04 || (dx < 0 && x <= 0.08) {
                target = 0.0
            } else if target >= 0.96 || (dx > 0 && x >= 0.92) {
                target = 1.0
            }

            target = max(0.0, min(1.0, target))
            if abs(target - current) >= 0.005 || target == 0.0 || target == 1.0 {
                _ = BacklightManager.shared.setBrightness(target)
                HUDOverlay.shared.showBrightness(target, source: "⌘ + Trackpad Slide")
            }
            lastX = x
        }
    }

    private func resetTracking() {
        trackingFingerID = -1
    }
}
