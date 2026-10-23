//
//  BacklightManager.swift
//  KeyGlow
//
//  Zero-dependency native controller for MacBook keyboard backlight.
//  Binds dynamically to Apple's private CoreBrightness framework.
//

import Foundation
import ObjectiveC

public final class BacklightManager: @unchecked Sendable {
    public static let shared = BacklightManager()

    private typealias GetBrightnessFn = @convention(c) (AnyObject, Selector, UInt64) -> Float
    private typealias SetBrightnessFn = @convention(c) (AnyObject, Selector, Float, UInt64) -> Bool

    private var clientInstance: AnyObject?
    private var getBrightnessFn: GetBrightnessFn?
    private var setBrightnessFn: SetBrightnessFn?
    private var getBrightnessSel: Selector?
    private var setBrightnessSel: Selector?

    public private(set) var keyboardID: UInt64 = 0
    public private(set) var isSupported: Bool = false
    public private(set) var originalBrightness: Float = 0.0
    private var hasSavedOriginal = false

    private let lock = NSLock()

    private init() {
        initializeClient()
    }

    private func initializeClient() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness", RTLD_NOW) else {
            return
        }
        _ = handle

        guard let clientClass = objc_getClass("KeyboardBrightnessClient") as? NSObject.Type else {
            return
        }

        let client = clientClass.init()
        self.clientInstance = client

        let copySel = NSSelectorFromString("copyKeyboardBacklightIDs")
        guard client.responds(to: copySel), let retained = client.perform(copySel) else {
            return
        }

        guard let ids = retained.takeRetainedValue() as? [Any], !ids.isEmpty else {
            return
        }

        if let firstID = ids.first as? UInt64 {
            self.keyboardID = firstID
        } else if let num = ids.first as? NSNumber {
            self.keyboardID = num.uint64Value
        } else {
            return
        }

        let getSel = NSSelectorFromString("brightnessForKeyboard:")
        let setSel = NSSelectorFromString("setBrightness:forKeyboard:")

        guard let getMethod = class_getInstanceMethod(object_getClass(client), getSel),
              let setMethod = class_getInstanceMethod(object_getClass(client), setSel) else {
            return
        }

        let getImp = method_getImplementation(getMethod)
        let setImp = method_getImplementation(setMethod)

        self.getBrightnessFn = unsafeBitCast(getImp, to: GetBrightnessFn.self)
        self.setBrightnessFn = unsafeBitCast(setImp, to: SetBrightnessFn.self)
        self.getBrightnessSel = getSel
        self.setBrightnessSel = setSel
        self.isSupported = true

        let current = self.getBrightness()
        self.originalBrightness = current
        self.hasSavedOriginal = true
    }

    public func getBrightness() -> Float {
        lock.lock()
        defer { lock.unlock() }

        guard isSupported, let client = clientInstance, let fn = getBrightnessFn, let sel = getBrightnessSel else {
            return 0.0
        }
        return fn(client, sel, keyboardID)
    }

    @discardableResult
    public func setBrightness(_ value: Float) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard isSupported, let client = clientInstance, let fn = setBrightnessFn, let sel = setBrightnessSel else {
            return false
        }
        let clamped = max(0.0, min(1.0, value))
        return fn(client, sel, clamped, keyboardID)
    }

    public func restoreOriginalBrightness() {
        if hasSavedOriginal {
            setBrightness(originalBrightness)
        }
    }
}
