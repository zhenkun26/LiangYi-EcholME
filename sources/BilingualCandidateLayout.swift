// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit

struct BilingualCandidateLayout {
  let size: NSSize
  let header: NSRect
  let cells: [NSRect]
  let footer: NSRect

  init(snapshot: CandidateSnapshot, maximumWidth: CGFloat, font: NSFont) {
    let limit = max(40, maximumWidth)
    let headerHeight: CGFloat = snapshot.preedit.isEmpty ? 0 : 24
    let inset: CGFloat = 8
    let gap: CGFloat = 4
    let count = snapshot.candidates.count
    let available = max(1, limit - inset * 2 - CGFloat(max(0, count - 1)) * gap)
    var widths = snapshot.candidates.map { candidate -> CGFloat in
      let primary = Self.primaryLine(candidate)
      let mainWidth = (primary as NSString).size(withAttributes: [.font: font]).width
      let subWidth = (candidate.subtitle.text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 12)]).width
      return min(240, max(64, max(mainWidth, subWidth) + 20))
    }
    // One horizontal row. Very wide text truncates in its own cell, never
    // wraps a subtitle underneath a different candidate or outside the screen.
    let natural = widths.reduce(0, +)
    if natural > available && natural > 0 {
      widths = widths.map { $0 * available / natural }
    }
    let minimum = min(limit, count == 0 ? 220 : 260)
    let width = min(limit, max(minimum, widths.reduce(0, +) + inset * 2 + CGFloat(max(0, count - 1)) * gap))
    let cellsHeight: CGFloat = count == 0 ? 0 : 56
    size = NSSize(width: ceil(width), height: headerHeight + cellsHeight + 28)
    header = NSRect(x: inset, y: 3, width: width - inset * 2, height: headerHeight)
    var x = inset
    cells = widths.map { width in
      defer { x += width + gap }
      return NSRect(x: x, y: headerHeight, width: width, height: cellsHeight)
    }
    footer = NSRect(x: inset, y: headerHeight + cellsHeight + 4, width: width - inset * 2, height: 20)
  }

  func candidateIndex(at point: NSPoint) -> Int? {
    cells.firstIndex { $0.contains(point) }
  }

  static func primaryLine(_ candidate: CandidateValue) -> String {
    let label = candidate.descriptor.label
    return label.isEmpty ? candidate.descriptor.primary : "\(label) \(candidate.descriptor.primary)"
  }

  static func panelFrame(size: NSSize, caret: NSRect, screen: NSRect) -> NSRect {
    let width = min(size.width, screen.width)
    let height = min(size.height, screen.height)
    var point = NSPoint(x: caret.minX, y: caret.minY - height - 5)
    if point.y < screen.minY { point.y = caret.maxY + 5 }
    point.x = min(max(point.x, screen.minX), screen.maxX - width)
    point.y = min(max(point.y, screen.minY), screen.maxY - height)
    return NSRect(origin: point, size: NSSize(width: width, height: height))
  }
}

enum BilingualCandidateRenderer {
  // Used by the existing SquirrelView and the standalone visual test harness.
  // Geometry is in flipped Cocoa points; Retina scaling belongs to AppKit.
  static func draw(snapshot: CandidateSnapshot, layout: BilingualCandidateLayout,
                   highlighted: Int, font: NSFont, background: NSColor, hovered: Int? = nil) {
    background.setFill()
    NSBezierPath(roundedRect: NSRect(origin: .zero, size: layout.size), xRadius: 9, yRadius: 9).fill()
    drawText(snapshot.preedit, in: layout.header, font: .systemFont(ofSize: 13), color: .secondaryLabelColor)
    for index in snapshot.candidates.indices {
      let cell = layout.cells[index]
      let candidate = snapshot.candidates[index]
      if index == highlighted {
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: cell, xRadius: 6, yRadius: 6).fill()
      } else if index == hovered {
        // Hover indicates a click target, never changes the keyboard selection.
        NSColor.keyboardFocusIndicatorColor.setStroke()
        let outline = NSBezierPath(roundedRect: cell.insetBy(dx: 1, dy: 1), xRadius: 6, yRadius: 6)
        outline.lineWidth = 1
        outline.stroke()
      }
      let primaryColor: NSColor = index == highlighted ? .alternateSelectedControlTextColor : .labelColor
      let subtitleColor: NSColor = index == highlighted ? .alternateSelectedControlTextColor : .secondaryLabelColor
      drawText(BilingualCandidateLayout.primaryLine(candidate),
               in: NSRect(x: cell.minX + 7, y: cell.minY + 5, width: max(1, cell.width - 14), height: 25),
               font: font, color: primaryColor)
      drawText(candidate.subtitle.text,
               in: NSRect(x: cell.minX + 7, y: cell.minY + 32, width: max(1, cell.width - 14), height: 19),
               font: .systemFont(ofSize: 12), color: subtitleColor)
    }
    let page = snapshot.page + 1
    let language = snapshot.direction == .chinese ? "中文 · 左⇧切英文" : "英文 · 左⇧切中文"
    let action = snapshot.examplesEnabled ? "⌥↩ 译文" : "译文关"
    drawText("\(language) · \(action) · \(page)", in: layout.footer, font: .systemFont(ofSize: 11), color: .secondaryLabelColor)
  }

  private static func drawText(_ text: String, in rect: NSRect, font: NSFont, color: NSColor) {
    guard rect.width > 0, rect.height > 0 else { return }
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byTruncatingTail
    (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
  }
}
