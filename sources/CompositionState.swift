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

  mutating func reset() { held = []; armed = nil }
  mutating func keyDown() { armed = nil }

  mutating func receive(_ event: ShiftModifierEvent) -> ShiftGesture {
    let key = event.keyCode
    guard key == ShiftModifierEvent.leftKey || key == ShiftModifierEvent.rightKey else {
      armed = nil // Another modifier interrupts a tap, even if released first.
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
    } else if held.contains(key) {
      // A sole Shift cannot be released while the aggregate flag remains set.
      // Without device bits that event is a duplicate/inconsistent press.
      if held.count > 1 { held.remove(key) }
    } else {
      held.insert(key)
    }
    let blocked = event.modifiers & ShiftModifierEvent.blockingMask != 0
    if !previous.contains(key), held.contains(key) {
      if previous.isEmpty, held.count == 1, !blocked {
        armed = key
        started = event.timestamp
      } else {
        armed = nil
      }
    } else if previous.contains(key), !held.contains(key) {
      let tapped = armed == key && held.isEmpty && !blocked &&
        event.timestamp >= started && event.timestamp - started <= 0.5
      armed = nil
      if tapped { return key == ShiftModifierEvent.leftKey ? .leftTap : .rightTap }
    } else {
      armed = nil // Inconsistent/duplicate flags cannot manufacture a tap.
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
  func keyDown() { shift.keyDown() }

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
      guard host.modeActive, host.modeToken.session == before.session,
            host.modeToken.generation == before.generation,
            (host.modeToken.revision == before.revision || host.modeToken.revision == before.revision &+ 1) else { return true }
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
