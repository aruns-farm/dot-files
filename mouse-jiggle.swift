import AppKit
import CoreGraphics
import Foundation

// Current mouse position (AppKit: origin bottom-left → flip to CG top-left)
let mouse = NSEvent.mouseLocation
let screenH = CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
let pos = CGPoint(x: mouse.x, y: screenH - mouse.y)

func postMouse(_ type: CGEventType, at p: CGPoint) {
    CGEvent(mouseEventSource: nil, mouseType: type,
            mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
}

func scroll(_ lines: Int32) {
    CGEvent(scrollWheelEvent2Source: nil, units: .line,
            wheelCount: 1, wheel1: lines, wheel2: 0, wheel3: 0)?.post(tap: .cghidEventTap)
}

// Move +20px then back
postMouse(.mouseMoved, at: CGPoint(x: pos.x + 20, y: pos.y))
Thread.sleep(forTimeInterval: 0.15)
postMouse(.mouseMoved, at: pos)
Thread.sleep(forTimeInterval: 0.1)

// Click at current position
postMouse(.leftMouseDown, at: pos)
Thread.sleep(forTimeInterval: 0.05)
postMouse(.leftMouseUp, at: pos)
Thread.sleep(forTimeInterval: 0.15)

// Scroll down then back up
scroll(4)
Thread.sleep(forTimeInterval: 0.25)
scroll(-4)
