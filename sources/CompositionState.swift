// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

enum InputDirection: String, Sendable {
  case chinese, english
}

struct CompositionToken: Hashable, Sendable {
  let session: UUID
  let generation: UInt64
  let revision: UInt64
}

struct CandidateIdentity: Hashable, Sendable {
  let token: CompositionToken
  let index: Int
}

enum ExampleSubtitle: Equatable, Sendable {
  case off, pending, missing, failed, ready(String)

  var text: String {
    switch self {
    case .off: return ""
    case .pending: return "…"
    case .missing: return "—"
    case .failed: return "!"
    case .ready(let text): return text
    }
  }
}

enum SubtitleDelivery: Equatable, Sendable {
  // Absent identities are dictionary misses. A failure is a separate case and
  // must not be cached or displayed as a miss.
  case resolved([CandidateIdentity: String])
  case unavailable
}

struct CandidateDescriptor: Equatable, Sendable {
  let primary: String
  let engineComment: String
  let label: String
  // Only a verified whole-composition preview permits translated insertion.
  // A Rime segment/comment is not a whole sentence commit preview.
  let fullCommitPreview: String?
}

struct CandidateValue: Equatable, Sendable {
  let id: CandidateIdentity
  let descriptor: CandidateDescriptor
  var subtitle: ExampleSubtitle
}

struct CandidateSnapshot: Equatable, Sendable {
  let token: CompositionToken
  let direction: InputDirection
  let rawInput: String
  let preedit: String
  var candidates: [CandidateValue]
  let highlighted: Int
  let page: Int
  let lastPage: Bool
  let examplesEnabled: Bool

  var highlightedCandidate: CandidateValue? {
    candidates.indices.contains(highlighted) ? candidates[highlighted] : nil
  }
}

// One controller owns this state, exclusively on its IMK/UI thread. Background
// work receives Sendable value snapshots, never this object or a host client.
final class CompositionSession {
  private let identifier = UUID()
  private var generation: UInt64 = 0
  private var revision: UInt64 = 0
  private(set) var active = false
  private(set) var snapshot: CandidateSnapshot?
  private(set) var englishInput = ""
  static let maximumEnglishLength = 256

  var token: CompositionToken {
    CompositionToken(session: identifier, generation: generation, revision: revision)
  }

  func activate() {
    generation &+= 1
    invalidate()
    active = true
  }

  func deactivate() {
    invalidate()
    generation &+= 1
    active = false
  }

  func invalidate() {
    revision &+= 1
    snapshot = nil
    englishInput = ""
  }

  @discardableResult
  func appendEnglish(_ text: String) -> Bool {
    guard active, englishInput.count + text.count <= Self.maximumEnglishLength else { return false }
    englishInput += text
    return true
  }

  func backspaceEnglish() {
    if !englishInput.isEmpty { englishInput.removeLast() }
  }

  @discardableResult
  func replace(direction: InputDirection, rawInput: String, preedit: String,
               candidates: [CandidateDescriptor], highlighted: Int, page: Int,
               lastPage: Bool, examplesEnabled: Bool) -> CandidateSnapshot? {
    guard active else { return nil }
    let safeHighlight = candidates.indices.contains(highlighted) ? highlighted : 0
    if let old = snapshot, old.direction == direction, old.rawInput == rawInput,
       old.preedit == preedit, old.candidates.map(\.descriptor) == candidates,
       old.highlighted == safeHighlight, old.page == page, old.lastPage == lastPage,
       old.examplesEnabled == examplesEnabled {
      return old
    }
    revision &+= 1
    let values = candidates.enumerated().map { index, descriptor in
      CandidateValue(id: CandidateIdentity(token: token, index: index),
                     descriptor: descriptor, subtitle: examplesEnabled ? .pending : .off)
    }
    let value = CandidateSnapshot(token: token, direction: direction, rawInput: rawInput,
                                  preedit: preedit, candidates: values, highlighted: safeHighlight,
                                  page: page, lastPage: lastPage, examplesEnabled: examplesEnabled)
    snapshot = value
    return value
  }

  func applyExamples(_ examples: [CandidateIdentity: String], for expected: CompositionToken) -> CandidateSnapshot? {
    applySubtitles(.resolved(examples), for: expected)
  }

  func applySubtitles(_ delivery: SubtitleDelivery, for expected: CompositionToken) -> CandidateSnapshot? {
    guard active, var value = snapshot, value.token == expected, value.examplesEnabled else { return nil }
    switch delivery {
    case .unavailable:
      for index in value.candidates.indices {
        value.candidates[index].subtitle = .failed
      }
    case .resolved(let examples):
      for index in value.candidates.indices {
        let id = value.candidates[index].id
        if let example = examples[id], !example.isEmpty, !example.contains(where: \.isNewline) {
          value.candidates[index].subtitle = .ready(example)
        } else {
          value.candidates[index].subtitle = .missing
        }
      }
    }
    snapshot = value
    return value
  }

  func candidate(_ id: CandidateIdentity) -> CandidateValue? {
    guard active, let value = snapshot, value.token == id.token,
          value.candidates.indices.contains(id.index), value.candidates[id.index].id == id else { return nil }
    return value.candidates[id.index]
  }

  func translatedText(for id: CandidateIdentity) -> String? {
    guard let candidate = candidate(id),
          candidate.descriptor.fullCommitPreview == candidate.descriptor.primary,
          case .ready(let text) = candidate.subtitle, !text.isEmpty else { return nil }
    return text
  }

  // Invalidate before external insertion. Reentrant deactivation and late
  // delivery cannot reserve this composition again, even when insertion fails.
  func reserveCommit(expected: CompositionToken) -> Bool {
    guard active, token == expected else { return false }
    invalidate()
    return true
  }
}

protocol CommitHost {
  func insert(_ text: String) -> Bool
}

struct ClosureCommitHost: CommitHost {
  let operation: (String) -> Bool
  func insert(_ text: String) -> Bool { operation(text) }
}

struct CommitCoordinator {
  @discardableResult
  func commit(_ text: String, expected: CompositionToken,
              state: CompositionSession, host: CommitHost) -> Bool {
    guard !text.isEmpty, state.reserveCommit(expected: expected) else { return false }
    // Never retry a host call with an uncertain result.
    return host.insert(text)
  }
}

enum CompositionKeyAction: Equatable {
  case engine, host, rawThenHost, raw, cancel, translated
  case englishSpace, englishBackspace, englishText(String)
}

enum CompositionKeyPolicy {
  static func action(keyCode: UInt16, text: String?, command: Bool, control: Bool,
                     option: Bool, shift: Bool, hasComposition: Bool,
                     englishInput: String, englishEnabled: Bool) -> CompositionKeyAction {
    let isReturn = keyCode == 36 || keyCode == 76
    if command { return .rawThenHost }
    if isReturn && option && !control && !shift {
      return hasComposition ? .translated : .host
    }
    if control || option { return englishInput.isEmpty ? .engine : .rawThenHost }
    if isReturn { return hasComposition ? .raw : .host }
    if keyCode == 53 { return hasComposition ? .cancel : .engine }
    if keyCode == 48 { return .rawThenHost }
    guard englishEnabled else { return .engine }
    if keyCode == 49 { return englishInput.isEmpty ? .host : .englishSpace }
    if keyCode == 51 && !englishInput.isEmpty { return .englishBackspace }
    if let text, text.count == 1, let scalar = text.unicodeScalars.first,
       (65...90).contains(scalar.value) || (97...122).contains(scalar.value) ||
       (!englishInput.isEmpty && (48...57).contains(scalar.value)) {
      return .englishText(text)
    }
    return .rawThenHost
  }
}

// Copied macOS modifier events. Device bits distinguish overlapping left/right
// Shift keys; remote events without those bits use the key code and held state.
struct ShiftModifierEvent {
  let keyCode: UInt16
  let modifiers: UInt
  let timestamp: TimeInterval

  static let leftKey: UInt16 = 56
  static let rightKey: UInt16 = 60
  static let shiftMask: UInt = 1 << 17
  static let capsLockMask: UInt = 1 << 16
  static let blockingMask: UInt = (1 << 18) | (1 << 19) | (1 << 20) | (1 << 23)
  // NX_DEVICELSHIFTKEYMASK / NX_DEVICERSHIFTKEYMASK from the macOS event ABI.
  static let leftDeviceMask: UInt = 0x2
  static let rightDeviceMask: UInt = 0x4
}

private enum ShiftGesture {
  case unrelated, consumed, leftTap, rightTap
}

private struct ShiftGestureTracker {
  private var held: Set<UInt16> = []
  private var armed: UInt16?
  private var started: TimeInterval = 0
  private var previousModifiers: UInt = 0

  mutating func reset() { held = []; armed = nil; previousModifiers = 0 }
  mutating func keyDown(modifiers: UInt) {
    armed = nil
    // A release can be omitted before the next keyDown. Reconcile physical
    // state without inventing a tap, so the next real tap is not swallowed.
    reconcileHeld(modifiers: modifiers)
    previousModifiers = modifiers
  }

  private mutating func reconcileHeld(modifiers: UInt) {
    if modifiers & ShiftModifierEvent.shiftMask == 0 {
      held = []
    } else if modifiers & (ShiftModifierEvent.leftDeviceMask | ShiftModifierEvent.rightDeviceMask) != 0 {
      held = []
      if modifiers & ShiftModifierEvent.leftDeviceMask != 0 { held.insert(ShiftModifierEvent.leftKey) }
      if modifiers & ShiftModifierEvent.rightDeviceMask != 0 { held.insert(ShiftModifierEvent.rightKey) }
    }
  }

  private func resolvedKey(_ event: ShiftModifierEvent) -> UInt16? {
    guard event.keyCode == 0 else { return event.keyCode }
    // Some event producers omit the hardware key code. Infer from device
    // changes or a known held side, never turn a right release into a left tap.
    let changes = previousModifiers ^ event.modifiers
    guard changes & (ShiftModifierEvent.blockingMask | ShiftModifierEvent.capsLockMask) == 0 else { return nil }
    let devices = changes & (ShiftModifierEvent.leftDeviceMask | ShiftModifierEvent.rightDeviceMask)
    if devices == ShiftModifierEvent.leftDeviceMask { return ShiftModifierEvent.leftKey }
    if devices == ShiftModifierEvent.rightDeviceMask { return ShiftModifierEvent.rightKey }
    if devices != 0 { return nil } // Both sides changed; do not guess a tap.
    if held.count == 1 { return held.first }
    if held.isEmpty, changes & ShiftModifierEvent.shiftMask != 0,
       event.modifiers & ShiftModifierEvent.shiftMask != 0, devices == 0 {
      return ShiftModifierEvent.leftKey // No side evidence: inherited left default.
    }
    return nil // Ambiguous overlap or an orphan release cannot switch mode.
  }

  mutating func receive(_ event: ShiftModifierEvent) -> ShiftGesture {
    defer { previousModifiers = event.modifiers }
    guard let key = resolvedKey(event), key == ShiftModifierEvent.leftKey || key == ShiftModifierEvent.rightKey else {
      armed = nil // Another modifier interrupts a tap, even if released first.
      reconcileHeld(modifiers: event.modifiers)
      let changes = previousModifiers ^ event.modifiers
      let shiftChanges = ShiftModifierEvent.shiftMask | ShiftModifierEvent.leftDeviceMask | ShiftModifierEvent.rightDeviceMask
      if event.keyCode == 0, changes & shiftChanges != 0,
         changes & (ShiftModifierEvent.blockingMask | ShiftModifierEvent.capsLockMask) == 0 {
        return .consumed // Ambiguous Shift events must not reach Rime as a tap.
      }
      return .unrelated
    }
    let previous = held
    let device = event.modifiers & (ShiftModifierEvent.leftDeviceMask | ShiftModifierEvent.rightDeviceMask)
    if event.modifiers & ShiftModifierEvent.shiftMask == 0 {
      held = []
    } else if device != 0 {
      held = []
      if device & ShiftModifierEvent.leftDeviceMask != 0 { held.insert(ShiftModifierEvent.leftKey) }
      if device & ShiftModifierEvent.rightDeviceMask != 0 { held.insert(ShiftModifierEvent.rightKey) }
    } else if held.contains(key), held.count > 1 {
      // The other Shift is still down, and this event has no device bits.
      held.remove(key)
    } else if !held.contains(key) {
      held.insert(key)
    }
    let blocked = event.modifiers & ShiftModifierEvent.blockingMask != 0
    if blocked {
      armed = nil
      return .consumed
    }
    // A physical Shift key often delivers a second flagsChanged while the same
    // keys remain down. That update must not cancel the tap already armed.
    if held == previous { return .consumed }
    if !previous.contains(key), held.contains(key) {
      if previous.isEmpty, held.count == 1 {
        armed = key
        started = event.timestamp
      } else {
        armed = nil
      }
    } else if previous.contains(key), !held.contains(key) {
      let tapped = armed == key && held.isEmpty &&
        event.timestamp >= started && event.timestamp - started <= 0.5
      armed = nil
      if tapped { return key == ShiftModifierEvent.leftKey ? .leftTap : .rightTap }
    } else {
      armed = nil
    }
    return .consumed
  }
}

protocol CompositionModeHost: AnyObject {
  var modeToken: CompositionToken { get }
  var modeActive: Bool { get }
  var modeASCII: Bool { get }
  var modeHasEnglishInput: Bool { get }
  func modeFinalizeRaw() -> Bool
  func modeSetASCII(_ enabled: Bool)
  func modeRightShiftTap(modifiers: UInt)
  func modeRefresh()
}

// Own both Shift gesture streams: Rime must not receive a press/release pair
// with the intervening frontend-consumed letter missing. A confirmed right tap
// is replayed as a pair to retain the schema's binding, not to invent one.
final class CompositionModeRouter {
  private var shift = ShiftGestureTracker()

  func reset() { shift.reset() }
  func keyDown(modifiers: UInt) { shift.keyDown(modifiers: modifiers) }

  // Menu and CLI selection share the same raw-finalization/focus guard as a
  // left tap. Selecting the already active language preserves composition.
  @discardableResult
  func setASCII(_ enabled: Bool, host: CompositionModeHost) -> Bool {
    shift.reset()
    guard host.modeActive else { return false }
    if host.modeASCII == enabled { host.modeRefresh(); return true }
    let before = host.modeToken
    guard host.modeFinalizeRaw(), canChangeMode(host, since: before) else { return false }
    host.modeSetASCII(enabled)
    if host.modeActive, host.modeToken.generation == before.generation { host.modeRefresh() }
    return host.modeActive && host.modeToken.generation == before.generation && host.modeASCII == enabled
  }

  private func canChangeMode(_ host: CompositionModeHost, since before: CompositionToken) -> Bool {
    host.modeActive && host.modeToken.session == before.session &&
      host.modeToken.generation == before.generation &&
      (host.modeToken.revision == before.revision || host.modeToken.revision == before.revision &+ 1)
  }

  static func usesEnglishComposer(ascii: Bool, examples: Bool, engineInput: String) -> Bool {
    // A schema/engine may enter inline ASCII with a live Chinese prefix. That
    // entire composition remains owned by Rime until it finishes.
    ascii && examples && engineInput.isEmpty
  }

  func handleModifiers(_ event: ShiftModifierEvent, host: CompositionModeHost) -> Bool {
    let gesture = shift.receive(event) // End mutation before any reentrant host call.
    if case .unrelated = gesture { return false }
    guard host.modeActive else { return true }
    switch gesture {
    case .leftTap, .rightTap:
      let before = host.modeToken
      let ascii = host.modeASCII
      // Left tap always finalizes raw input. Right tap preserves Chinese schema
      // selection semantics but must finish frontend English before Rime runs.
      if gesture == .leftTap || host.modeHasEnglishInput {
        guard host.modeFinalizeRaw() else { return true }
      }
      guard canChangeMode(host, since: before) else { return true }
      // A raw reservation advances once. Any extra revision means an external
      // host callback cancelled/replaced input; do not overwrite that decision.
      if gesture == .leftTap { host.modeSetASCII(!ascii) }
      else { host.modeRightShiftTap(modifiers: event.modifiers) }
      if host.modeActive, host.modeToken.generation == before.generation { host.modeRefresh() }
    case .consumed, .unrelated: break
    }
    return true
  }
}
