// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit

// Creates only an offscreen view of EcholME's own settings with synthetic app
// IDs. It neither activates a window nor reads any other application's UI.
@main
struct ContextSettingsPreview {
  static func main() {
    do {
      guard CommandLine.arguments.count == 2 else {
        throw PreviewError.failed("usage: settings-preview NEW_OUTPUT.png")
      }
      let destination = URL(fileURLWithPath: CommandLine.arguments[1])
      guard !FileManager.default.fileExists(atPath: destination.path) else {
        throw PreviewError.failed("Output already exists; choose a fresh path")
      }
      _ = NSApplication.shared
      NSApp.setActivationPolicy(.prohibited)
      let controller = ContextSettingsWindow.shared
      var settings = ContextSettings()
      settings.forceRules = ["test.synthetic.editor": .english, "test.synthetic.notes": .chinese]
      settings.learningEnabled = true
      controller.prepareForDisplay(settings: settings,
        status: "Settings applied. Explicit language changes finish pending text; automatic decisions wait for an empty composition.")
      guard let window = controller.window, let content = window.contentView else {
        throw PreviewError.failed("Settings content view is unavailable")
      }
      window.appearance = NSAppearance(named: .aqua)
      content.layoutSubtreeIfNeeded()
      content.displayIfNeeded()
      var failures: [String] = []
      if window.isVisible { failures.append("Preview unexpectedly made the window visible") }
      var controlCount = 0
      var labelCount = 0
      func examine(_ view: NSView) {
        guard !view.isHidden else { return }
        // Scroll contents may intentionally extend beyond the viewport.
        guard !(view is NSScrollView) else { return }
        if let control = view as? NSControl {
          controlCount += 1
          let rect = control.convert(control.bounds, to: content)
          if !content.bounds.insetBy(dx: -1, dy: -1).contains(rect) || rect.width <= 0 || rect.height <= 0 {
            failures.append("Control outside content bounds: \(type(of: control)) \(NSStringFromRect(rect))")
          }
          if let field = control as? NSTextField, !field.isEditable, !field.stringValue.isEmpty,
             let cell = field.cell {
            labelCount += 1
            let needed = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: field.bounds.width, height: 10_000))
            if needed.height > field.bounds.height + 1 {
              failures.append("Label height clips text: \(field.stringValue.prefix(40))")
            }
          }
        }
        for child in view.subviews { examine(child) }
      }
      examine(content)
      if controlCount == 0 || labelCount == 0 { failures.append("Settings control hierarchy is empty") }
      guard let bitmap = content.bitmapImageRepForCachingDisplay(in: content.bounds) else {
        throw PreviewError.failed("Cannot create settings bitmap")
      }
      content.cacheDisplay(in: content.bounds, to: bitmap)
      // A hidden content view has no window-server backdrop. Composite its
      // pixels over the ordinary window background for a readable preview.
      guard let flattened = NSBitmapImageRep(bitmapDataPlanes: nil,
        pixelsWide: bitmap.pixelsWide, pixelsHigh: bitmap.pixelsHigh,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let context = NSGraphicsContext(bitmapImageRep: flattened) else {
        throw PreviewError.failed("Cannot create preview background")
      }
      let pixelRect = NSRect(x: 0, y: 0, width: bitmap.pixelsWide, height: bitmap.pixelsHigh)
      window.effectiveAppearance.performAsCurrentDrawingAppearance {
        context.cgContext.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.cgContext.fill(pixelRect)
      }
      guard let pixels = bitmap.cgImage else { throw PreviewError.failed("Settings bitmap has no image pixels") }
      context.cgContext.setBlendMode(.normal)
      context.cgContext.draw(pixels, in: pixelRect)
      guard let data = flattened.representation(using: .png, properties: [:]) else {
        throw PreviewError.failed("Cannot encode settings bitmap")
      }
      try data.write(to: destination, options: .withoutOverwriting)
      let report: [String: Any] = [
        "status": failures.isEmpty ? "PASS" : "FAIL",
        "scope": "Offscreen synthetic settings layout; no installed IMK, button interaction, or host UI acceptance",
        "control_count": controlCount,
        "label_count": labelCount,
        "content_width": content.bounds.width,
        "content_height": content.bounds.height,
        "window_visible": window.isVisible,
        "failures": failures,
        "png": destination.path
      ]
      let encoded = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
      print(String(decoding: encoded, as: UTF8.self))
      if !failures.isEmpty { exit(1) }
    } catch {
      fputs("Settings preview failed: \(error)\n", stderr)
      exit(1)
    }
  }

  private enum PreviewError: Error { case failed(String) }
}
