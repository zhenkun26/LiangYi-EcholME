// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit
import ApplicationServices
import Carbon

// The adapter owns AX objects on one background queue. IMK clients never cross
// that boundary. Tests inject metadata/text for synthetic fields only.
protocol ContextAccess: AnyObject {
  var trusted: Bool { get }
  var secureInput: Bool { get }
  var expired: Bool { get }
  func focusedField() -> ContextFieldKind?
  func caretLocation() -> Int?
  func textBeforeCaret(location: Int, length: Int) -> String?
  func focusUnchanged() -> Bool
}

enum ContextSnapshotReader {
  static let maximumUTF16 = 128

  static func read(_ access: ContextAccess, includeText: Bool = true) -> ContextEvidence {
    func missing(_ availability: ContextAvailability, field: ContextFieldKind = .unknown) -> ContextEvidence {
      ContextEvidence(field: field, language: nil, confidence: 0,
                      availability: availability, reason: availability.rawValue)
    }
    if access.secureInput {
      return ContextDetector.detect(text: "", field: .secure)
    }
    guard access.trusted else { return missing(.denied) }
    guard !access.expired, let field = access.focusedField() else {
      return missing(access.expired ? .timedOut : .unsupported)
    }
    // Never ask secure/unknown elements for text, even when manual mode is set.
    if field == .secure { return ContextDetector.detect(text: "", field: .secure) }
    guard field != .unknown else { return missing(.unsupported) }
    guard includeText else { return missing(.disabled, field: field) }
    guard !access.expired, let caret = access.caretLocation(), caret >= 0, caret < Int.max - maximumUTF16 else {
      return missing(access.expired ? .timedOut : .unsupported, field: field)
    }
    let length = min(caret, maximumUTF16)
    var text = ""
    if length > 0 {
      if access.secureInput { return ContextDetector.detect(text: "", field: .secure) }
      guard !access.expired, access.focusUnchanged() else { return missing(access.expired ? .timedOut : .stale) }
      if access.secureInput { return ContextDetector.detect(text: "", field: .secure) }
      guard !access.expired, let value = access.textBeforeCaret(location: caret - length, length: length),
            value.utf16.count <= length else {
        return missing(access.expired ? .timedOut : .unsupported, field: field)
      }
      text = value
    }
    guard !access.expired else { return missing(.timedOut) }
    if access.secureInput { return ContextDetector.detect(text: "", field: .secure) }
    guard access.focusUnchanged() else { return missing(.stale) }
    if access.secureInput { return ContextDetector.detect(text: "", field: .secure) }
    guard !access.expired else { return missing(.timedOut) }
    return ContextDetector.detect(text: text, field: field)
  }
}

private final class AXContextAccess: ContextAccess {
  let processID: pid_t
  private let deadline = ProcessInfo.processInfo.systemUptime + 0.15
  private let application: AXUIElement
  private var focused: AXUIElement?
  var trusted: Bool { AXIsProcessTrusted() } // No options dictionary or prompt.
  var secureInput: Bool { IsSecureEventInputEnabled() }
  var expired: Bool { ProcessInfo.processInfo.systemUptime >= deadline }

  init(processID: pid_t) {
    self.processID = processID
    application = AXUIElementCreateApplication(processID)
    AXUIElementSetMessagingTimeout(application, 0.025)
  }

  private func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    guard !expired else { return nil }
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name, &value) == .success else { return nil }
    return value
  }

  private func currentElement() -> AXUIElement? {
    guard let value = attribute(application, kAXFocusedUIElementAttribute as CFString),
          CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
    // Type is checked before the CoreFoundation cast.
    return (value as! AXUIElement)
  }

  func focusedField() -> ContextFieldKind? {
    guard let element = currentElement() else { return nil }
    focused = element
    AXUIElementSetMessagingTimeout(element, 0.025)
    let role = attribute(element, kAXRoleAttribute as CFString) as? String
    let subrole = attribute(element, kAXSubroleAttribute as CFString) as? String
    if subrole == (kAXSecureTextFieldSubrole as String) { return .secure }
    guard role == (kAXTextFieldRole as String) || role == (kAXTextAreaRole as String) ||
            role == (kAXComboBoxRole as String) else { return .unknown }
    return subrole == (kAXSearchFieldSubrole as String) ? .search : .text
  }

  func caretLocation() -> Int? {
    guard let focused, let value = attribute(focused, kAXSelectedTextRangeAttribute as CFString),
          CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
    let axValue = value as! AXValue
    guard AXValueGetType(axValue) == .cfRange else { return nil }
    var range = CFRange()
    guard AXValueGetValue(axValue, .cfRange, &range), range.location >= 0, range.length == 0 else { return nil }
    // Selected text is deliberately not read; evidence comes before an empty caret.
    return range.location
  }

  func textBeforeCaret(location: Int, length: Int) -> String? {
    guard !expired, let focused, location >= 0, length > 0,
          length <= ContextSnapshotReader.maximumUTF16 else { return nil }
    var range = CFRange(location: location, length: length)
    guard let parameter = AXValueCreate(.cfRange, &range) else { return nil }
    var value: CFTypeRef?
    guard AXUIElementCopyParameterizedAttributeValue(focused, kAXStringForRangeParameterizedAttribute as CFString,
                                                     parameter, &value) == .success else { return nil }
    return value as? String
  }

  func focusUnchanged() -> Bool {
    guard let focused, let current = currentElement() else { return false }
    return CFEqual(focused, current)
  }
}

// At most one running AX operation and one replaceable pending request. A
// watchdog releases the UI decision after 200 ms; AX messaging timeouts are
// best effort, not a promise to forcibly interrupt every synchronous IPC.
final class ContextCapture {
  static let shared = ContextCapture()
  private let queue = DispatchQueue(label: "EcholME.context", qos: .userInitiated)
  private let lock = NSLock()
  private var pending: (() -> Void)?
  private var running = false
  private let read: (pid_t, Bool) -> ContextEvidence

  init(read: @escaping (pid_t, Bool) -> ContextEvidence = { processID, includeText in
    ContextSnapshotReader.read(AXContextAccess(processID: processID), includeText: includeText)
  }) {
    self.read = read
  }

  @discardableResult
  func request(processID: pid_t, includeText: Bool, completion: @escaping (ContextEvidence) -> Void) -> ContextCaptureRequest {
    precondition(Thread.isMainThread)
    let ticket = ContextCaptureRequest(completion)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      ticket.deliver(ContextEvidence(field: .unknown, language: nil, confidence: 0,
                                    availability: .timedOut, reason: "timedOut"))
    }
    lock.lock()
    pending = {
      guard !ticket.delivered else { return }
      let evidence = self.read(processID, includeText)
      DispatchQueue.main.async { ticket.deliver(evidence) }
    }
    let start = !running
    running = true
    lock.unlock()
    if start { queue.async { self.drain() } }
    return ticket
  }

  private func drain() {
    while true {
      lock.lock()
      let operation = pending
      pending = nil
      if operation == nil { running = false }
      lock.unlock()
      guard let operation else { return }
      operation()
    }
  }
}

final class ContextCaptureRequest {
  private let lock = NSLock()
  private var completed = false
  private let completion: (ContextEvidence) -> Void
  init(_ completion: @escaping (ContextEvidence) -> Void) { self.completion = completion }
  var delivered: Bool { lock.lock(); defer { lock.unlock() }; return completed }
  func cancel() { lock.lock(); completed = true; lock.unlock() }
  func deliver(_ evidence: ContextEvidence) {
    precondition(Thread.isMainThread)
    lock.lock()
    let first = !completed
    completed = true
    lock.unlock()
    if first { completion(evidence) }
  }
}
