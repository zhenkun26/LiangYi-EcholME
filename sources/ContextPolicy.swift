// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

enum PrimaryInputMode: String, Codable {
  case auto, chinese, english, off
}

enum ContextFieldKind: String, Sendable {
  case unknown, text, search, code, secure
}

enum ContextAvailability: String, Sendable {
  case ready, denied, unsupported, timedOut, stale, disabled
}

// A value snapshot contains classifications only, never nearby document text.
struct ContextEvidence: Equatable, Sendable {
  let field: ContextFieldKind
  let language: InputDirection?
  let confidence: Double
  let availability: ContextAvailability
  let reason: String

  static let unavailable = ContextEvidence(
    field: .unknown, language: nil, confidence: 0,
    availability: .unsupported, reason: "context_unavailable")

  var requiresSecureMetadataReview: Bool {
    field == .unknown && availability == .disabled && reason == "secure_event_input"
  }

  func acceptingCapture(_ incoming: ContextEvidence) -> ContextEvidence {
    // Skipped, stale or failed AX metadata cannot disprove a known secure field.
    field == .secure && incoming.field == .unknown ? self : incoming
  }
}

// The global OS flag may hide the field's actual AX type. Its release permits
// one metadata-only review, not an immediate assertion that the field is safe.
// Request identity prevents a cancelled/late review from clearing protection.
struct SecureContextReview {
  private(set) var required = false
  private var requestID: UUID?
  private var retryBlockedUntilReset = false

  mutating func observeGlobalInput(_ enabled: Bool) {
    if enabled { required = true; requestID = nil }
  }

  mutating func observeCapture(_ evidence: ContextEvidence) {
    if evidence.requiresSecureMetadataReview { required = true; requestID = nil }
  }

  mutating func beginIfNeeded(secureEventInput: Bool, mode: PrimaryInputMode,
                            knownSecureField: Bool) -> UUID? {
    guard required, !retryBlockedUntilReset, !secureEventInput, mode != .off,
          !knownSecureField, requestID == nil else { return nil }
    let identifier = UUID()
    requestID = identifier
    return identifier
  }

  func accepts(_ identifier: UUID) -> Bool { requestID == identifier }

  @discardableResult
  mutating func complete(_ identifier: UUID, evidence: ContextEvidence, secureEventInput: Bool) -> Bool {
    guard accepts(identifier) else { return false }
    requestID = nil
    if evidence.availability == .stale {
      // The queried field changed: keep protection and retire this request.
      // Only focus/source reactivation can restart sampling. Repeated keys,
      // callbacks and settings changes must not turn failure into AX polling.
      required = true
      retryBlockedUntilReset = true
      return true
    }
    // Denied/unsupported/timed-out metadata uses the existing fallback policy;
    // completion does not mean the field has been verified non-sensitive.
    required = secureEventInput || evidence.requiresSecureMetadataReview
    return true
  }

  mutating func cancel(_ identifier: UUID? = nil) {
    if identifier == nil || requestID == identifier { requestID = nil }
  }

  mutating func reset() { self = SecureContextReview() }
}

enum ContextDetector {
  static let maximumScalars = 256

  static func detect(text: String, field: ContextFieldKind,
                     availability: ContextAvailability = .ready) -> ContextEvidence {
    // Check safety and availability before examining any supplied text. The
    // capture adapter has its own smaller host-read limit; this is defense in
    // depth for callers and does not make an unbounded IPC read safe.
    if field == .secure {
      return ContextEvidence(field: .secure, language: nil, confidence: 1,
                             availability: availability, reason: "secure_field")
    }
    guard availability == .ready else {
      return ContextEvidence(field: field, language: nil, confidence: 0,
                             availability: availability, reason: "context_\(availability.rawValue)")
    }
    if field == .code {
      return ContextEvidence(field: .code, language: .english, confidence: 1,
                             availability: .ready, reason: "code_field")
    }

    let bounded = String(String.UnicodeScalarView(text.unicodeScalars.suffix(maximumScalars)))
    let trimmed = bounded.trimmingCharacters(in: .whitespacesAndNewlines)
    // A known search field stays neutral. Its query may contain syntax without
    // being a source-code editor; ordinary language evidence still applies.
    if field != .search && isCodeLiteral(trimmed) {
      return ContextEvidence(field: .code, language: .english, confidence: 0.98,
                             availability: .ready, reason: "code_literal")
    }

    var han = 0
    var asciiLetters = 0
    var otherLetters = 0
    for scalar in bounded.unicodeScalars {
      switch scalar.value {
      case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF,
           0x20000...0x2FA1F, 0x30000...0x323AF:
        han += 1
      case 0x41...0x5A, 0x61...0x7A:
        asciiLetters += 1
      default:
        if CharacterSet.letters.contains(scalar) { otherLetters += 1 }
      }
    }
    let letters = han + asciiLetters + otherLetters
    guard letters > 0 else {
      return ContextEvidence(field: field, language: nil, confidence: 0,
                             availability: .ready, reason: "no_language_evidence")
    }
    let chineseRatio = Double(han) / Double(letters)
    let englishRatio = Double(asciiLetters) / Double(letters)
    if han >= 2 && chineseRatio >= 0.8 {
      return ContextEvidence(field: field, language: .chinese, confidence: chineseRatio,
                             availability: .ready, reason: "han_dominant")
    }
    if asciiLetters >= 4 && englishRatio >= 0.8 {
      // ASCII-script dominance is a zh/en input preference hint. It does not
      // claim semantic language identification or distinguish Latin languages.
      return ContextEvidence(field: field, language: .english, confidence: englishRatio,
                             availability: .ready, reason: "latin_dominant")
    }
    return ContextEvidence(field: field, language: nil, confidence: 0,
                           availability: .ready, reason: "ambiguous_language")
  }

  private static func isCodeLiteral(_ text: String) -> Bool {
    guard !text.isEmpty else { return false }
    // Anchor recognizers to the whole small snapshot so a URL or an equals
    // sign embedded in ordinary prose does not turn the field into code.
    let patterns = [
      #"^(?:https?|ftp)://[A-Za-z0-9][^\s]*$"#,
      #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#,
      #"^[A-Za-z_][A-Za-z0-9_.]*\s*(?:=|\+=|-=|:=)\s*[^=\s].*$"#,
      #"^(?:let|var|const)\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*:[^=]+)?\s*=\s*\S.*$"#,
      #"^[A-Za-z_][A-Za-z0-9_.]*\s*\([^\n]*\)\s*;?$"#,
      #"^\{\s*\"[^\"]+\"\s*:\s*[^\n]+\}$"#
    ]
    return patterns.contains { text.range(of: $0, options: .regularExpression) != nil }
  }
}

struct LearnedPreference: Codable, Equatable {
  var direction: InputDirection
  var count: Int
}

struct ContextSettings: Codable, Equatable {
  var mode: PrimaryInputMode = .auto
  var globalDirection: InputDirection = .chinese
  var contextEnabled = true
  var learningEnabled = false
  var forceRules: [String: InputDirection] = [:]
  var learned: [String: LearnedPreference] = [:]
}

struct ModeResolution: Equatable {
  let direction: InputDirection
  let translationsAllowed: Bool
  let passthrough: Bool
  let reason: String
  let confidence: Double
}

enum ContextSamplingPolicy {
  static func refreshAfterSettings(mode: PrimaryInputMode, contextEnabled: Bool,
                                   hadComposition: Bool, evidence: ContextEvidence) -> Bool {
    mode == .auto && contextEnabled && !hadComposition && evidence.field != .secure &&
      (evidence.availability != .ready || evidence.language == nil)
  }
}

enum ModeResolver {
  static func resolve(bundleID: String, evidence: ContextEvidence,
                      manual: InputDirection?, settings: ContextSettings,
                      composingDirection: InputDirection? = nil,
                      secureEventInput: Bool = false,
                      secureMetadataPending: Bool = false) -> ModeResolution {
    // The global OS flag is a live input, not persistent field evidence. Its
    // release must restore ordinary resolution without clearing AX protection.
    if evidence.field == .secure || secureEventInput {
      return ModeResolution(direction: .english, translationsAllowed: false,
                            passthrough: true,
                            reason: evidence.field == .secure ? "secure_field" : "secure_event_input",
                            confidence: 1)
    }
    if settings.mode == .off {
      return ModeResolution(direction: .english, translationsAllowed: false,
                            passthrough: true, reason: "mode_off", confidence: 1)
    }
    if secureMetadataPending {
      return ModeResolution(direction: .english, translationsAllowed: false,
                            passthrough: true, reason: "secure_metadata_pending", confidence: 1)
    }

    let requested = requestedDirection(bundleID: bundleID, evidence: evidence,
                                       manual: manual, settings: settings)
    // Explicit menu/Shift changes must first finalize through the guarded
    // commit boundary. A late asynchronous context reply never rewrites a
    // live composition, even if settings changed while the reply was pending.
    if let composingDirection, requested.direction != composingDirection {
      return ModeResolution(direction: composingDirection, translationsAllowed: true,
                            passthrough: false, reason: "composition_frozen", confidence: 1)
    }
    return requested
  }

  private static func requestedDirection(bundleID: String, evidence: ContextEvidence,
                                         manual: InputDirection?, settings: ContextSettings) -> ModeResolution {
    func result(_ direction: InputDirection, _ reason: String, _ confidence: Double) -> ModeResolution {
      ModeResolution(direction: direction, translationsAllowed: true,
                     passthrough: false, reason: reason, confidence: confidence)
    }
    if let manual { return result(manual, "manual_focus", 1) }
    switch settings.mode {
    case .chinese: return result(.chinese, "manual_setting", 1)
    case .english: return result(.english, "manual_setting", 1)
    case .auto, .off: break
    }
    if let forced = settings.forceRules[bundleID], !bundleID.isEmpty {
      return result(forced, "force_rule", 1)
    }
    if settings.contextEnabled && evidence.availability == .ready {
      if evidence.field == .code { return result(.english, "code_field", 0.98) }
      if let language = evidence.language,
         evidence.confidence.isFinite, (0.75...1).contains(evidence.confidence) {
        return result(language, evidence.reason, evidence.confidence)
      }
    }
    if settings.learningEnabled, !bundleID.isEmpty,
       let learned = settings.learned[bundleID], learned.count >= 3 {
      let confidence = min(0.9, 0.6 + Double(min(learned.count, 6)) * 0.05)
      return result(learned.direction, "learned_preference", confidence)
    }
    switch bundleID {
    case "com.apple.dt.Xcode", "com.apple.Terminal", "com.googlecode.iterm2":
      return result(.english, "builtin_app", 0.6)
    default:
      return result(settings.globalDirection, "global_default", 0.2)
    }
  }
}

// Owned by the controller on its UI thread. Workers receive only the UUID;
// accepting a result requires the current request and active-focus checks.
final class ContextRequestGate {
  private var current: UUID?

  @discardableResult
  func begin() -> UUID {
    let request = UUID()
    current = request
    return request
  }

  func invalidate() { current = nil }

  func accepts(_ request: UUID) -> Bool { current == request }

  func accepts(_ request: UUID, expected: CompositionToken, current: CompositionToken,
               evidence: ContextEvidence) -> Bool {
    guard accepts(request), expected.session == current.session,
          expected.generation == current.generation else { return false }
    // A snapshot racing our own marked text or a later commit is no longer
    // direction evidence. Secure-field protection or a metadata-only safety
    // review may interrupt a changed composition, never a request/focus boundary.
    return expected == current || evidence.field == .secure || evidence.requiresSecureMetadataReview
  }
}
