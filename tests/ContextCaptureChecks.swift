// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

private final class SyntheticContextAccess: ContextAccess {
  var trusted = true
  var secureInitially = false
  var secureAfterTextRead = false
  var secureAfterCaretRead = false
  var secureAfterFieldRead = false
  var secureOnFocusCheck: Int?
  var secureSequence: [Bool] = []
  var expiredInitially = false
  var expireAfterFieldRead = false
  var expireAfterTextRead = false
  var expireAfterFocusCheck = false
  var field: ContextFieldKind? = .text
  var caret: Int? = 5
  var reply: String? = "hello"
  var sameFocus = true
  private(set) var fieldReads = 0
  private(set) var caretReads = 0
  private(set) var textReads: [(location: Int, length: Int)] = []
  private(set) var focusChecks = 0
  var secureInput: Bool {
    if !secureSequence.isEmpty { return secureSequence.removeFirst() }
    return secureInitially || (secureAfterTextRead && !textReads.isEmpty)
      || (secureAfterCaretRead && caretReads > 0)
      || (secureAfterFieldRead && fieldReads > 0)
      || (secureOnFocusCheck.map { focusChecks >= $0 } ?? false)
  }
  var expired: Bool {
    expiredInitially || (expireAfterFieldRead && fieldReads > 0)
      || (expireAfterTextRead && !textReads.isEmpty)
      || (expireAfterFocusCheck && focusChecks > 0)
  }
  func focusedField() -> ContextFieldKind? { fieldReads += 1; return field }
  func caretLocation() -> Int? { caretReads += 1; return caret }
  func textBeforeCaret(location: Int, length: Int) -> String? {
    textReads.append((location, length))
    return reply
  }
  func focusUnchanged() -> Bool { focusChecks += 1; return sameFocus }
}

// All preference reads/writes stay inside this dictionary. Tests never create,
// rewrite, or delete a preferences plist or a real application domain.
private final class MemoryDefaults: UserDefaults {
  var bytes: [String: Data] = [:]
  private(set) var writes = 0
  override func data(forKey defaultName: String) -> Data? { bytes[defaultName] }
  override func set(_ value: Any?, forKey defaultName: String) {
    precondition(value is Data)
    bytes[defaultName] = value as? Data
    writes += 1
  }
}

private final class NotificationCounter: @unchecked Sendable {
  var count = 0
}

@main
struct ContextCaptureChecks {
  private static var checks: [String] = []
  private static var failures: [String] = []

  private static func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    checks.append(name)
    if !condition() { failures.append(name) }
  }

  static func main() {
    precondition(Thread.isMainThread)
    captureChecks()
    preferenceChecks()
    let report: [String: Any] = [
      "status": failures.isEmpty ? "PASS" : "FAIL",
      "check_count": checks.count,
      "checks": checks,
      "failures": failures,
      "scope": "Synthetic ContextAccess and in-memory UserDefaults; no real document access, permission requests, or installed IMK acceptance"
    ]
    if let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
      print(String(decoding: data, as: UTF8.self))
    }
    if !failures.isEmpty { exit(1) }
  }

  private static func captureChecks() {
    func wasSkippedForSecureInput(_ evidence: ContextEvidence) -> Bool {
      evidence.field == .unknown && evidence.language == nil && evidence.confidence == 0 &&
        evidence.availability == .disabled && evidence.reason == "secure_event_input"
    }
    let secure = SyntheticContextAccess()
    secure.secureInitially = true
    secure.trusted = false
    let secureSkipped = ContextSnapshotReader.read(secure)
    check(wasSkippedForSecureInput(secureSkipped),
          "secure input outranks denied AX access without inventing AX secure field evidence")
    check(secure.fieldReads == 0 && secure.caretReads == 0 && secure.textReads.isEmpty,
          "secure event input performs no host reads")
    var review = SecureContextReview()
    review.observeCapture(secureSkipped)
    let protected = ModeResolver.resolve(bundleID: "test.synthetic.editor", evidence: secureSkipped,
                                        manual: .chinese, settings: ContextSettings(), secureEventInput: secure.secureInput,
                                        secureMetadataPending: review.required)
    check(protected.passthrough && !protected.translationsAllowed,
          "skipped capture still honors the currently active global secure flag")
    secure.secureInitially = false
    let waiting = ModeResolver.resolve(bundleID: "test.synthetic.editor", evidence: secureSkipped,
                                      manual: .chinese, settings: ContextSettings(), secureEventInput: secure.secureInput,
                                      secureMetadataPending: review.required)
    check(waiting.passthrough && !waiting.translationsAllowed && waiting.reason == "secure_metadata_pending",
          "global secure release waits for field metadata after skipped capture")
    if let identifier = review.beginIfNeeded(secureEventInput: false, mode: .chinese, knownSecureField: false) {
      let metadata = ContextSnapshotReader.read(secure, includeText: false)
      check(review.complete(identifier, evidence: metadata, secureEventInput: false),
            "denied metadata-only review finishes the bounded safety wait")
      let fallback = ModeResolver.resolve(bundleID: "test.synthetic.editor", evidence: metadata,
                                         manual: .chinese, settings: ContextSettings(), secureMetadataPending: review.required)
      check(metadata.availability == .denied && !fallback.passthrough && fallback.reason == "manual_focus",
            "denied metadata uses the explicit fallback without claiming a verified safe field")
    } else {
      check(false, "released global secure input schedules metadata review")
    }

    let securePulse = SyntheticContextAccess()
    securePulse.secureSequence = [false, true, false]
    let pulseEvidence = ContextSnapshotReader.read(securePulse)
    check(wasSkippedForSecureInput(pulseEvidence) && !securePulse.secureInput,
          "a global secure pulse during capture remains an unavailable result after release")
    check(securePulse.fieldReads == 1 && securePulse.caretReads == 1 && securePulse.textReads.isEmpty &&
          securePulse.focusChecks == 0,
          "capture stops at the first observed secure pulse before any text query")

    let denied = SyntheticContextAccess()
    denied.trusted = false
    check(ContextSnapshotReader.read(denied).availability == .denied, "denied access returns denied evidence")
    check(denied.fieldReads == 0 && denied.textReads.isEmpty, "denied access does not query a focused field")

    let secureField = SyntheticContextAccess()
    secureField.field = .secure
    check(ContextSnapshotReader.read(secureField).field == .secure, "secure field metadata prevents text analysis")
    check(secureField.caretReads == 0 && secureField.textReads.isEmpty, "secure field does not request caret or text")
    let protectedField = ModeResolver.resolve(bundleID: "test.synthetic.editor",
                                             evidence: ContextSnapshotReader.read(secureField),
                                             manual: .chinese, settings: ContextSettings(), secureEventInput: false)
    check(protectedField.passthrough && protectedField.reason == "secure_field" && !protectedField.translationsAllowed,
          "actual AX secure metadata continues protecting the field without the global flag")

    let metadataOnly = SyntheticContextAccess()
    let metadata = ContextSnapshotReader.read(metadataOnly, includeText: false)
    check(metadata.field == .text && metadata.availability == .disabled && metadata.language == nil,
          "context-disabled capture returns field metadata without language analysis")
    check(metadataOnly.fieldReads == 1 && metadataOnly.focusChecks == 1 &&
          metadataOnly.caretReads == 0 && metadataOnly.textReads.isEmpty,
          "metadata-only capture validates focus without requesting caret or nearby text")
    let staleMetadata = SyntheticContextAccess()
    staleMetadata.sameFocus = false
    let staleMetadataEvidence = ContextSnapshotReader.read(staleMetadata, includeText: false)
    check(staleMetadataEvidence.availability == .stale && staleMetadataEvidence.field == .unknown &&
          staleMetadataEvidence.language == nil,
          "metadata-only capture rejects a field change before final delivery")
    check(staleMetadata.focusChecks == 1 && staleMetadata.caretReads == 0 && staleMetadata.textReads.isEmpty,
          "stale metadata validation never reads document text")
    let expiredMetadata = SyntheticContextAccess()
    expiredMetadata.expireAfterFieldRead = true
    check(ContextSnapshotReader.read(expiredMetadata, includeText: false).availability == .timedOut &&
          expiredMetadata.focusChecks == 0,
          "metadata-only capture honors expiration immediately after field lookup")
    let expiredFinalMetadata = SyntheticContextAccess()
    expiredFinalMetadata.expireAfterFocusCheck = true
    check(ContextSnapshotReader.read(expiredFinalMetadata, includeText: false).availability == .timedOut &&
          expiredFinalMetadata.focusChecks == 1,
          "metadata-only capture honors expiration caused by its final focus check")
    let secureFieldMetadata = SyntheticContextAccess()
    secureFieldMetadata.secureAfterFieldRead = true
    check(wasSkippedForSecureInput(ContextSnapshotReader.read(secureFieldMetadata, includeText: false)) &&
          secureFieldMetadata.focusChecks == 0 && secureFieldMetadata.textReads.isEmpty,
          "metadata-only capture stops when global security starts during field lookup")
    let secureFinalMetadata = SyntheticContextAccess()
    secureFinalMetadata.secureOnFocusCheck = 1
    check(wasSkippedForSecureInput(ContextSnapshotReader.read(secureFinalMetadata, includeText: false)) &&
          secureFinalMetadata.focusChecks == 1 && secureFinalMetadata.caretReads == 0,
          "metadata-only capture rejects global security enabled by its final focus check")
    let metadataSecure = SyntheticContextAccess()
    metadataSecure.field = .secure
    check(ContextSnapshotReader.read(metadataSecure, includeText: false).field == .secure,
          "metadata-only capture still identifies secure fields")
    check(metadataSecure.caretReads == 0 && metadataSecure.textReads.isEmpty,
          "metadata-only secure capture never requests caret or text")

    let unknown = SyntheticContextAccess()
    unknown.field = .unknown
    check(ContextSnapshotReader.read(unknown).availability == .unsupported, "unknown field falls back")
    check(unknown.caretReads == 0 && unknown.textReads.isEmpty, "unknown field does not request text")

    let absentField = SyntheticContextAccess()
    absentField.field = nil
    check(ContextSnapshotReader.read(absentField).availability == .unsupported, "missing field falls back")

    let expired = SyntheticContextAccess()
    expired.expiredInitially = true
    check(ContextSnapshotReader.read(expired).availability == .timedOut, "expired request returns timed out")
    check(expired.fieldReads == 0 && expired.textReads.isEmpty, "expired request does not begin host reads")

    let expiredField = SyntheticContextAccess()
    expiredField.expireAfterFieldRead = true
    check(ContextSnapshotReader.read(expiredField).availability == .timedOut, "field lookup expiration returns timed out")
    check(expiredField.caretReads == 0 && expiredField.textReads.isEmpty, "expiration between field and caret prevents more reads")

    let bounded = SyntheticContextAccess()
    bounded.caret = 200
    bounded.reply = String(repeating: "a", count: 128)
    check(ContextSnapshotReader.read(bounded).language == .english, "bounded English context resolves English")
    check(bounded.textReads.count == 1 && bounded.textReads[0].location == 72 && bounded.textReads[0].length == 128,
          "context asks only for 128 UTF-16 units immediately before caret")

    let nearStart = SyntheticContextAccess()
    check(ContextSnapshotReader.read(nearStart).language == .english, "short available prefix resolves English")
    check(nearStart.textReads.count == 1 && nearStart.textReads[0].location == 0 && nearStart.textReads[0].length == 5,
          "caret near field start requests only available preceding range")

    let chinese = SyntheticContextAccess()
    chinese.caret = 4
    chinese.reply = "中文测试"
    check(ContextSnapshotReader.read(chinese).language == .chinese, "synthetic Chinese prefix resolves Chinese")

    for (name, position) in [("negative", -1), ("overflow-sized", Int.max)] {
      let invalid = SyntheticContextAccess()
      invalid.caret = position
      check(ContextSnapshotReader.read(invalid).availability == .unsupported, "\(name) caret falls back")
      check(invalid.textReads.isEmpty, "\(name) caret never constructs a text query")
    }
    let missingCaret = SyntheticContextAccess()
    missingCaret.caret = nil
    check(ContextSnapshotReader.read(missingCaret).availability == .unsupported && missingCaret.textReads.isEmpty,
          "missing caret does not read text")

    let oversized = SyntheticContextAccess()
    oversized.reply = "hello world"
    check(ContextSnapshotReader.read(oversized).language == nil, "oversized host reply is not analyzed")
    check(ContextSnapshotReader.read(oversized).availability == .unsupported, "oversized reply falls back")

    let utf16Oversized = SyntheticContextAccess()
    utf16Oversized.caret = 3
    utf16Oversized.reply = "𠀀𠀁"
    check(ContextSnapshotReader.read(utf16Oversized).availability == .unsupported,
          "reply length limit uses UTF-16 units rather than character count")

    let noReply = SyntheticContextAccess()
    noReply.reply = nil
    check(ContextSnapshotReader.read(noReply).availability == .unsupported, "unavailable text query falls back")

    let stale = SyntheticContextAccess()
    stale.sameFocus = false
    let staleEvidence = ContextSnapshotReader.read(stale)
    check(staleEvidence.availability == .stale && staleEvidence.language == nil,
          "focus change rejects otherwise valid text evidence")
    check(stale.textReads.isEmpty, "focus change before text query prevents that query")

    let expiredReply = SyntheticContextAccess()
    expiredReply.expireAfterTextRead = true
    let expiredEvidence = ContextSnapshotReader.read(expiredReply)
    check(expiredEvidence.availability == .timedOut && expiredEvidence.language == nil,
          "deadline after host reply rejects text evidence")

    let secureDuringRead = SyntheticContextAccess()
    secureDuringRead.secureAfterTextRead = true
    let newlySecure = ContextSnapshotReader.read(secureDuringRead)
    check(wasSkippedForSecureInput(newlySecure),
          "secure input enabled during a read discards language evidence without retaining a false field type")
    check(secureDuringRead.textReads.count == 1 && secureDuringRead.focusChecks == 1,
          "secure input observed after the text reply prevents further host access")

    let secureDuringCaret = SyntheticContextAccess()
    secureDuringCaret.secureAfterCaretRead = true
    check(wasSkippedForSecureInput(ContextSnapshotReader.read(secureDuringCaret)),
          "secure input enabled by caret lookup records a transient capture suppression")
    check(secureDuringCaret.textReads.isEmpty, "secure input enabled by caret lookup prevents text query")

    let secureDuringPreReadFocus = SyntheticContextAccess()
    secureDuringPreReadFocus.secureOnFocusCheck = 1
    check(wasSkippedForSecureInput(ContextSnapshotReader.read(secureDuringPreReadFocus)),
          "secure input enabled during pre-read focus check records a transient capture suppression")
    check(secureDuringPreReadFocus.textReads.isEmpty,
          "secure input enabled during pre-read focus check prevents text query")

    let secureDuringFinalFocus = SyntheticContextAccess()
    secureDuringFinalFocus.secureOnFocusCheck = 2
    let secureFinalEvidence = ContextSnapshotReader.read(secureDuringFinalFocus)
    check(wasSkippedForSecureInput(secureFinalEvidence),
          "secure input enabled during final focus check discards language evidence without an AX secure claim")

    let empty = SyntheticContextAccess()
    empty.caret = 0
    let emptyEvidence = ContextSnapshotReader.read(empty)
    check(emptyEvidence.availability == .ready && emptyEvidence.language == nil, "empty field provides neutral ready evidence")
    check(empty.textReads.isEmpty && empty.focusChecks == 1, "empty field checks focus without a text query")
  }

  private static func preferenceChecks() {
    let key = "EcholME.synthetic.context"
    let defaults = MemoryDefaults()
    let store = ContextPreferences(defaults: defaults, storageKey: key)
    check(store.settings == ContextSettings() && defaults.writes == 0, "absent preferences load defaults without writing")
    check(!store.settings.learningEnabled, "learning starts disabled")
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    check(store.settings.learned.isEmpty && defaults.writes == 0, "manual choices are not recorded before opt in")

    let notifications = NotificationCounter()
    let observer = NotificationCenter.default.addObserver(forName: ContextPreferences.didChange, object: store, queue: nil) { _ in
      notifications.count += 1
    }
    defer { NotificationCenter.default.removeObserver(observer) }
    check(store.update { $0.globalDirection = .english }, "explicit valid setting update succeeds")
    check(defaults.writes == 1 && notifications.count == 1, "actual update persists and posts exactly one notification")
    check(store.update { $0.globalDirection = .english }, "same setting update succeeds idempotently")
    check(defaults.writes == 1 && notifications.count == 1, "same setting update neither writes nor posts notification")
    let savedBytes = defaults.bytes[key]
    check(!store.update { $0.forceRules["invalid app id"] = .chinese }, "invalid rule ID rejects whole update")
    check(defaults.bytes[key] == savedBytes && store.settings.forceRules.isEmpty && notifications.count == 1,
          "rejected update preserves persisted bytes state and notification count")
    check(ContextPreferences(defaults: defaults, storageKey: key).settings.globalDirection == .english,
          "valid stored preferences round trip")

    check(store.update { $0.learningEnabled = true }, "learning can be explicitly enabled")
    let beforeLearningNotifications = notifications.count
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    check(store.settings.learned["test.synthetic.editor"]?.count == 1, "first manual choice creates one learned vote")
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    check(store.settings.learned["test.synthetic.editor"]?.count == 3, "repeated manual choices clamp at three votes")
    let writesAtLimit = defaults.writes
    store.recordManual(.english, bundleID: "test.synthetic.editor")
    check(defaults.writes == writesAtLimit, "saturated learned preference avoids redundant writes")
    store.recordManual(.chinese, bundleID: "test.synthetic.editor")
    check(store.settings.learned["test.synthetic.editor"] == LearnedPreference(direction: .chinese, count: 1),
          "direction reversal resets learned confidence")
    check(notifications.count == beforeLearningNotifications, "learning does not reenter mode resolution via notifications")
    let learnedBeforeInvalid = store.settings.learned
    store.recordManual(.english, bundleID: "invalid\napp")
    check(store.settings.learned == learnedBeforeInvalid, "invalid learned ID is ignored")
    check(!store.update { $0.learned["test.synthetic.editor"]?.count = 4 }, "out of range learned count rejects update")
    check(!store.update { $0.learned["test.synthetic.editor"]?.count = 0 }, "zero learned count rejects update")

    for invalid in ["", "a b", "a\tb", "a\nb", ".app", "app.", "app..id", "应用.id", String(repeating: "a", count: 256)] {
      check(!ContextPreferences.isValidBundleID(invalid), "invalid bundle ID shape \(checks.count) rejected")
    }
    check(ContextPreferences.isValidBundleID("io.github.synthetic.Editor-1_2"), "ordinary mixed-case bundle ID accepted")
    check(ContextPreferences.isValidBundleID(String(repeating: "a", count: 255)), "255-byte bundle ID accepted at boundary")

    let capacityDefaults = MemoryDefaults()
    let capacity = ContextPreferences(defaults: capacityDefaults, storageKey: key)
    check(capacity.update {
      $0.learningEnabled = true
      $0.forceRules = Dictionary(uniqueKeysWithValues: (0..<128).map { ("test.app\($0)", .english) })
    }, "128 distinct app IDs fit preference entry limit")
    let fullBytes = capacityDefaults.bytes[key]
    check(!capacity.update { $0.forceRules["test.extra"] = .chinese }, "129th distinct force-rule app is rejected")
    check(capacityDefaults.bytes[key] == fullBytes && capacity.settings.forceRules.count == 128,
          "entry-limit rejection preserves existing force rules and bytes")
    capacity.recordManual(.chinese, bundleID: "test.extra")
    check(capacity.settings.learned.isEmpty, "learning a new app respects shared app-entry limit")
    capacity.recordManual(.chinese, bundleID: "test.app0")
    check(capacity.settings.learned["test.app0"]?.count == 1,
          "force and learned entries for the same app share one capacity slot")
    let beforeLarge = capacityDefaults.bytes[key]
    check(!capacity.update { settings in
      settings.forceRules = [:]
      settings.learned = [:]
      for index in 0..<128 {
        let id = "test." + String(repeating: "a", count: 240) + ".\(index)"
        settings.forceRules[id] = .english
        settings.learned[id] = LearnedPreference(direction: .chinese, count: 3)
      }
    }, "encoded preferences above 64 KiB reject even within app count limit")
    check(capacityDefaults.bytes[key] == beforeLarge, "size-limit rejection preserves stored bytes")

    for malformed in [Data("not JSON".utf8), Data("{}".utf8), Data(repeating: 0x20, count: 65_537)] {
      let corrupt = MemoryDefaults()
      corrupt.bytes[key] = malformed
      check(ContextPreferences(defaults: corrupt, storageKey: key).settings == ContextSettings(),
            "invalid or oversized persisted payload \(checks.count) falls back safely")
      check(corrupt.bytes[key] == malformed && corrupt.writes == 0,
            "invalid stored payload \(checks.count) is preserved until explicit save")
    }
    var invalidSettings = ContextSettings()
    invalidSettings.learned["test.app"] = LearnedPreference(direction: .english, count: 9)
    let invalidEncoded = MemoryDefaults()
    invalidEncoded.bytes[key] = try? JSONEncoder().encode(invalidSettings)
    check(ContextPreferences(defaults: invalidEncoded, storageKey: key).settings == ContextSettings(),
          "structurally valid JSON with invalid learned count is rejected")
  }
}
