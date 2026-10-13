// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit

final class ModeHUD {
  static let shared = ModeHUD()
  private let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                              backing: .buffered, defer: true)
  private let label = NSTextField(labelWithString: "")
  private var generation = UUID()
  private var owner: UUID?

  private init() {
    panel.level = .popUpMenu
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = true
    panel.ignoresMouseEvents = true
    panel.hidesOnDeactivate = false
    panel.collectionBehavior = [.transient, .fullScreenAuxiliary]
    let background = NSVisualEffectView()
    background.material = .popover
    background.state = .active
    background.wantsLayer = true
    background.layer?.cornerRadius = 8
    label.font = .systemFont(ofSize: 14, weight: .medium)
    label.alignment = .center
    background.addSubview(label)
    panel.contentView = background
  }

  func show(_ text: String, caret: NSRect?, owner: UUID) {
    self.owner = owner
    generation = UUID()
    let expected = generation
    label.stringValue = text
    label.sizeToFit()
    let size = NSSize(width: min(500, max(120, label.frame.width + 28)), height: 36)
    let point = caret?.origin ?? NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main else { return }
    let visible = screen.visibleFrame
    let origin = NSPoint(x: min(max(point.x, visible.minX), visible.maxX - size.width),
                         y: min(max(point.y - size.height - 6, visible.minY), visible.maxY - size.height))
    panel.setFrame(NSRect(origin: origin, size: size), display: false)
    label.frame = NSRect(x: 14, y: 9, width: size.width - 28, height: 19)
    panel.alphaValue = 1
    panel.orderFrontRegardless()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
      guard let self, self.generation == expected else { return }
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.15
        self.panel.animator().alphaValue = 0
      } completionHandler: { [weak self] in
        guard let self, self.generation == expected else { return }
        self.panel.orderOut(nil)
      }
    }
  }

  func hide(owner: UUID) {
    guard self.owner == owner else { return }
    generation = UUID()
    panel.orderOut(nil)
  }
}
