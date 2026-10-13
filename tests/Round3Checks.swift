// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

private enum CheckError: Error { case failed(String) }

@main
struct Round3Checks {
  private static var checks: [String] = []

  static func check(_ condition: @autoclosure () -> Bool, _ name: String) throws {
    guard condition() else { throw CheckError.failed(name) }
    checks.append(name)
  }

  static func main() {
    do {
      try detectorChecks()
      try resolverChecks()
      try settingsAndRequestChecks()
      try check(ContextSamplingPolicy.refreshAfterSettings(mode: .auto, contextEnabled: true,
                 hadComposition: false, evidence: .unavailable), "idle Auto selection requests missing context")
      try check(!ContextSamplingPolicy.refreshAfterSettings(mode: .auto, contextEnabled: true,
                 hadComposition: true, evidence: .unavailable), "Auto after raw commit does not reread own output")
      try check(!ContextSamplingPolicy.refreshAfterSettings(mode: .off, contextEnabled: true,
                 hadComposition: false, evidence: .unavailable), "Off settings never initiate context text capture")
      try check(!ContextSamplingPolicy.refreshAfterSettings(mode: .chinese, contextEnabled: true,
                 hadComposition: false, evidence: .unavailable), "explicit language settings do not initiate text capture")
      try check(!ContextSamplingPolicy.refreshAfterSettings(mode: .auto, contextEnabled: false,
                 hadComposition: false, evidence: .unavailable), "disabled context setting avoids text resampling")
      try check(!ContextSamplingPolicy.refreshAfterSettings(mode: .auto, contextEnabled: true,
                 hadComposition: false, evidence: ContextDetector.detect(text: "hello", field: .text)),
                "existing pre-composition language evidence is reused")
      let report: [String: Any] = ["status": "PASS", "check_count": checks.count, "checks": checks]
      let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
      print(String(decoding: data, as: UTF8.self))
    } catch {
      fputs("Round 3 policy checks failed: \(error)\n", stderr)
      exit(1)
    }
  }

  private static func detectorChecks() throws {
    func detect(_ text: String, field: ContextFieldKind = .text) -> ContextEvidence {
      ContextDetector.detect(text: text, field: field)
    }
    try check(detect("你好，今天我们一起测试。").language == .chinese,
              "Chinese prose resolves Chinese")
    try check(detect("Please continue writing here.").language == .english,
              "English prose resolves English")
    try check(detect("hello").language == .english, "English word is sufficient context")
    try check(detect("你好").language == .chinese, "two Han characters are sufficient context")
    try check(detect("𠀀𠀁").language == .chinese, "supplementary Han characters are recognized")
    try check(detect("a").language == nil && detect("hi").language == nil,
              "short Latin fragments stay ambiguous")
    try check(detect("中").language == nil, "single Han character stays ambiguous")
    try check(detect("你好 hello").language == nil,
              "balanced Chinese and Latin context stays ambiguous")
    try check(detect("这是中文句子 test").language == nil,
              "mixed context below dominance threshold stays ambiguous")
    try check(detect("欢迎再次来到这里 a").language == .chinese,
              "dominant Chinese can contain a Latin letter")
    try check(detect("Please continue writing 中文").language == .english,
              "dominant Latin can contain Han characters")
    try check(detect("12345 == %@ • 😀").language == nil,
              "punctuation numbers and emoji do not choose a language")
    try check(detect("").reason == "no_language_evidence", "empty field has no language evidence")
    try check(detect("Привет мир").language == nil, "unsupported script falls back")
    try check(detect("こんにちは世界").language == nil,
              "mixed Kana and Han is not misclassified as Chinese")
    try check(detect("日本語のテストです").language == nil,
              "Japanese mixed script remains outside the zh en classifier")
    try check(detect("x = 42").field == .code, "assignment literal is recognized")
    try check(detect("let greeting = \"hello\"").field == .code,
              "declaration and assignment are recognized together")
    try check(detect("var count: Int = 3").field == .code,
              "typed declaration is recognized")
    try check(detect("call(value);").field == .code, "single function call is recognized")
    try check(detect("{\"count\": 2}").field == .code, "JSON object literal is recognized")
    try check(detect("https://example.invalid/path?a=b").field == .code,
              "standalone URL selects literal English input")
    try check(detect("test@example.invalid").field == .code,
              "standalone email selects literal English input")
    try check(detect("The result = a useful explanation.").field == .text,
              "an equals sign in prose is not enough to identify code")
    try check(detect("请查看 https://example.invalid/path 里面的说明。").field == .text,
              "URL inside a sentence does not classify the entire field as code")
    try check(detect("x = 42", field: .search).field == .search,
              "search metadata stays neutral for syntax queries")
    try check(detect("hello", field: .search).language == .english,
              "search fields can use nearby language evidence")
    try check(detect("", field: .code).language == .english,
              "known code field needs no document text")
    let secure = detect("hello", field: .secure)
    try check(secure.field == .secure && secure.language == nil,
              "secure field does not inspect text for a language")
    let denied = ContextDetector.detect(text: "hello", field: .text, availability: .denied)
    try check(denied.language == nil && denied.reason == "context_denied",
              "denied capture ignores supplied text")
    let timedOut = ContextDetector.detect(text: "你好", field: .text, availability: .timedOut)
    try check(timedOut.language == nil, "timed out capture does not use stale text")
    let bounded = detect(String(repeating: "中", count: 1_000) + String(repeating: "a", count: 256))
    try check(bounded.language == .english, "distant prefix does not outweigh bounded caret context")
    try check(!detect("synthetic sample alpha").reason.contains("sample"),
              "evidence reason does not retain the supplied document text")
  }

  private static func resolverChecks() throws {
    let empty = ContextEvidence.unavailable
    let chinese = ContextDetector.detect(text: "这是一个中文测试", field: .text)
    let english = ContextDetector.detect(text: "hello world", field: .text)
    let secure = ContextDetector.detect(text: "", field: .secure)
    let code = ContextDetector.detect(text: "", field: .code)
    func resolve(_ settings: ContextSettings = ContextSettings(),
                 bundle: String = "org.example.editor", evidence: ContextEvidence = .unavailable,
                 manual: InputDirection? = nil, composing: InputDirection? = nil) -> ModeResolution {
      ModeResolver.resolve(bundleID: bundle, evidence: evidence, manual: manual,
                           settings: settings, composingDirection: composing)
    }
    try check(resolve(evidence: empty).direction == .chinese,
              "unavailable context follows the Chinese global default")
    try check(resolve(bundle: "com.apple.dt.Xcode").direction == .english,
              "Xcode has an English fallback")
    try check(resolve(bundle: "com.apple.Terminal").direction == .english,
              "Terminal has an English fallback")
    try check(resolve(bundle: "com.googlecode.iterm2").direction == .english,
              "iTerm has an English fallback")
    try check(resolve(bundle: "com.apple.dt.Xcode.spoof").direction == .chinese,
              "built in application rules match exact identifiers")
    try check(resolve(bundle: "com.apple.dt.Xcode", evidence: chinese).direction == .chinese,
              "nearby Chinese text outranks built in Xcode fallback")
    try check(resolve(evidence: english).direction == .english,
              "nearby English text outranks the global default")
    try check(resolve(evidence: code).direction == .english,
              "code field outranks the global default")
    var settings = ContextSettings()
    settings.forceRules["org.example.editor"] = .chinese
    try check(resolve(settings, evidence: english).direction == .chinese,
              "forced app rule outranks language evidence")
    try check(resolve(settings, evidence: code).direction == .chinese,
              "forced app rule outranks code field")
    try check(resolve(settings, manual: .english).reason == "manual_focus",
              "current manual choice outranks forced app rule")
    settings.mode = .chinese
    try check(resolve(settings, evidence: english).direction == .chinese,
              "persistent Chinese mode outranks context")
    settings.mode = .english
    try check(resolve(settings).direction == .english,
              "persistent English mode outranks forced app rule")
    try check(resolve(settings, manual: .chinese).direction == .chinese,
              "current focus choice outranks persistent mode")
    let protected = resolve(settings, evidence: secure, manual: .chinese, composing: .chinese)
    try check(protected.direction == .english && protected.passthrough && !protected.translationsAllowed,
              "secure field overrides manual choice and a live composition")
    settings.mode = .off
    let off = resolve(settings, manual: .chinese, composing: .chinese)
    try check(off.direction == .english && off.passthrough && !off.translationsAllowed,
              "Off bypasses composition and translation regardless of manual choice")
    try check(resolve(settings, evidence: secure).reason == "secure_field",
              "secure field is recorded ahead of Off mode")
    settings = ContextSettings()
    settings.contextEnabled = false
    try check(resolve(settings, evidence: english).direction == .chinese,
              "context opt out ignores nearby language")
    try check(resolve(settings, evidence: code).direction == .chinese,
              "context opt out ignores code classification")
    try check(resolve(settings, evidence: secure).passthrough,
              "context opt out does not disable secure field protection")
    settings.learningEnabled = true
    settings.learned["org.example.editor"] = LearnedPreference(direction: .english, count: 2)
    try check(resolve(settings).direction == .chinese,
              "two manual choices do not activate a learned rule")
    settings.learned["org.example.editor"]?.count = 3
    try check(resolve(settings).reason == "learned_preference",
              "three consistent choices activate an enabled learned rule")
    settings.learningEnabled = false
    try check(resolve(settings).direction == .chinese,
              "disabled learning does not apply stored preferences")
    settings.learningEnabled = true
    settings.contextEnabled = true
    try check(resolve(settings, evidence: chinese).direction == .chinese,
              "language evidence outranks learned preference")
    settings.forceRules["org.example.editor"] = .chinese
    try check(resolve(settings).direction == .chinese,
              "forced app rule outranks learned preference")
    settings.forceRules = [:]
    settings.learned["com.apple.Terminal"] = LearnedPreference(direction: .chinese, count: 3)
    try check(resolve(settings, bundle: "com.apple.Terminal").direction == .chinese,
              "learned preference outranks built in application default")
    settings.learned["org.example.editor"]?.count = Int.max
    try check(resolve(settings).confidence.isFinite && resolve(settings).confidence <= 1,
              "extreme learned count cannot overflow confidence")
    settings.learned["org.example.editor"]?.count = -4
    try check(resolve(settings).direction == .chinese,
              "invalid negative learned count cannot activate a preference")
    settings.learned[""] = LearnedPreference(direction: .english, count: 3)
    settings.forceRules[""] = .english
    try check(resolve(settings, bundle: "").direction == .chinese,
              "missing bundle identifier never applies blank app rules")
    settings = ContextSettings()
    for availability in [ContextAvailability.denied, .unsupported, .timedOut, .stale, .disabled] {
      let evidence = ContextEvidence(field: .text, language: .english, confidence: 1,
                                     availability: availability, reason: "synthetic")
      try check(resolve(settings, evidence: evidence).direction == .chinese,
                "\(availability.rawValue) evidence cannot switch primary direction")
    }
    for confidence in [-0.1, 0.74, 1.01, Double.nan, Double.infinity] {
      let evidence = ContextEvidence(field: .text, language: .english, confidence: confidence,
                                     availability: .ready, reason: "synthetic")
      try check(resolve(settings, evidence: evidence).direction == .chinese,
                "invalid or weak confidence \(confidence) falls back")
    }
    let frozen = resolve(evidence: english, composing: .chinese)
    try check(frozen.direction == .chinese && frozen.reason == "composition_frozen",
              "late context cannot change the direction of an active composition")
    try check(resolve(evidence: chinese, composing: .english).direction == .english,
              "English composition is equally stable against Chinese context")
    try check(resolve(evidence: english, composing: .english).reason == "latin_dominant",
              "matching composition does not obscure the effective evidence")
    try check(resolve(manual: .english, composing: .chinese).direction == .chinese,
              "manual switch must finalize the old composition before resolving")
    try check(resolve(evidence: english).direction == .english,
              "new idle composition can use the previously deferred direction")
    settings.globalDirection = .english
    try check(resolve(settings).direction == .english,
              "user global fallback applies when other signals are absent")
    let ordinary = resolve(evidence: chinese)
    try check(ordinary.translationsAllowed && !ordinary.passthrough,
              "ordinary language resolution keeps bilingual composition available")
  }

  private static func settingsAndRequestChecks() throws {
    let defaults = ContextSettings()
    try check(defaults.mode == .auto && defaults.contextEnabled && !defaults.learningEnabled,
              "default mode uses context without retaining learned choices")
    var settings = defaults
    settings.mode = .english
    settings.forceRules["org.example.editor"] = .chinese
    settings.learned["org.example.editor"] = LearnedPreference(direction: .english, count: 3)
    let encoded = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(ContextSettings.self, from: encoded)
    try check(decoded == settings, "settings round trip preserves explicit and learned priorities")
    var malformed = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
    malformed["mode"] = "future_unsupported_mode"
    let malformedData = try JSONSerialization.data(withJSONObject: malformed)
    try check((try? JSONDecoder().decode(ContextSettings.self, from: malformedData)) == nil,
              "unknown mode is rejected rather than silently changing input behavior")
    malformed["mode"] = "auto"
    malformed["forceRules"] = ["org.example.editor": "unsupported_direction"]
    let malformedRules = try JSONSerialization.data(withJSONObject: malformed)
    try check((try? JSONDecoder().decode(ContextSettings.self, from: malformedRules)) == nil,
              "invalid forced direction is rejected during configuration load")

    let gate = ContextRequestGate()
    try check(!gate.accepts(UUID()), "unstarted capture rejects an unsolicited response")
    let first = gate.begin()
    try check(gate.accepts(first), "active capture accepts its matching response")
    let second = gate.begin()
    try check(!gate.accepts(first) && gate.accepts(second),
              "new capture rejects a delayed response from the preceding field")
    gate.invalidate()
    try check(!gate.accepts(second), "focus loss invalidates the outstanding response")
    let third = gate.begin()
    try check(gate.accepts(third) && !gate.accepts(first) && !gate.accepts(second),
              "new focus cannot revive a prior request identity")

    let composition = CompositionSession()
    composition.activate()
    let captureToken = composition.token
    let language = ContextDetector.detect(text: "synthetic language sample", field: .text)
    let secure = ContextDetector.detect(text: "", field: .secure)
    try check(gate.accepts(third, expected: captureToken, current: composition.token, evidence: language),
              "unchanged idle capture accepts matching composition identity")
    composition.replace(direction: .chinese, rawInput: "nihao", preedit: "ni hao",
                        candidates: [], highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)
    try check(!gate.accepts(third, expected: captureToken, current: composition.token, evidence: language),
              "capture racing our own preedit cannot determine the next primary language")
    try check(gate.accepts(third, expected: captureToken, current: composition.token, evidence: secure),
              "same focus secure evidence can interrupt a changed composition")
    let precommitToken = composition.token
    try check(composition.reserveCommit(expected: precommitToken),
              "synthetic commit reserves and invalidates the active composition")
    try check(!gate.accepts(third, expected: precommitToken, current: composition.token, evidence: language),
              "capture predating a commit cannot apply to the following idle state")
    try check(gate.accepts(third, expected: precommitToken, current: composition.token, evidence: secure),
              "same focus secure evidence survives the commit revision boundary")
    try check(!gate.accepts(first, expected: composition.token, current: composition.token, evidence: secure),
              "secure classification cannot revive a stale request UUID")
    let previousFocus = composition.token
    composition.deactivate()
    composition.activate()
    try check(!gate.accepts(third, expected: previousFocus, current: composition.token, evidence: secure),
              "secure classification cannot cross a focus generation")
    let otherComposition = CompositionSession()
    otherComposition.activate()
    try check(!gate.accepts(third, expected: composition.token, current: otherComposition.token, evidence: secure),
              "secure classification cannot cross controller sessions")
    gate.invalidate()
    try check(!gate.accepts(third, expected: composition.token, current: composition.token, evidence: secure),
              "invalidated capture rejects secure evidence even for identical tokens")
  }
}
