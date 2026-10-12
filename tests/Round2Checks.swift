// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

private enum CheckError: Error { case failed(String) }

private final class FakeHost: CommitHost {
  var inserts: [String] = []
  func insert(_ text: String) -> Bool { inserts.append(text); return true }
}

@main
struct Round2Checks {
  static var checks: [String] = []
  static func check(_ condition: @autoclosure () -> Bool, _ name: String) throws {
    guard condition() else { throw CheckError.failed(name) }
    checks.append(name)
  }

  static func main() {
    do {
      guard CommandLine.arguments.count == 4 else {
        fputs("usage: round2-checks index corpus manifest\n", stderr)
        exit(2)
      }
      let index = URL(fileURLWithPath: CommandLine.arguments[1])
      let corpus = URL(fileURLWithPath: CommandLine.arguments[2])
      let manifest = URL(fileURLWithPath: CommandLine.arguments[3])
      let report = try run(index: index, corpus: corpus, manifest: manifest)
      let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
      print(String(decoding: data, as: UTF8.self))
    } catch {
      fputs("Round 2 checks failed: \(error)\n", stderr)
      exit(1)
    }
  }

  static func run(index: URL, corpus: URL, manifest: URL) throws -> [String: Any] {
    let lexicon = LocalLexicon()
    let clock = ContinuousClock()
    let loadStart = clock.now
    try check(lexicon.loadSynchronously(from: index), "lexicon index loads")
    let loadMs = milliseconds(loadStart.duration(to: clock.now))
    let counts = lexicon.counts
    let manifestObject = try JSONSerialization.jsonObject(with: Data(contentsOf: manifest)) as? [String: Any]
    let manifestCounts = manifestObject?["counts"] as? [String: Any]
    try check(int(manifestCounts?["english_headwords"]) == counts.english && counts.english >= 2000,
              "at least 2000 deduplicated English headwords")
    try check(int(manifestCounts?["english_phrases"]) == counts.phrases && counts.phrases > 0,
              "English phrases counted separately")
    try check(int(manifestCounts?["chinese_simplified_keys"]) == counts.chinese,
              "Chinese index count matches manifest")
    try check(int(manifestCounts?["chinese_single_character"]) == counts.singleCharacters && counts.singleCharacters > 0,
              "single-character Chinese entries counted separately")
    try check(int(manifestCounts?["chinese_multicharacter"]) == counts.chinese - counts.singleCharacters
              && counts.chinese - counts.singleCharacters > 0,
              "multi-character Chinese entries counted separately")

    let corpusObject = try JSONSerialization.jsonObject(with: Data(contentsOf: corpus)) as? [String: Any]
    var forward = 0
    var reverse = 0
    for item in array(corpusObject?["chinese_to_english"]) {
      let primary = item["primary"] as? String ?? ""
      let subtitle = item["subtitle"] as? String ?? ""
      try check(lexicon.meaning(.chinese, primary) == .ready(subtitle), "Chinese corpus \(primary)")
      forward += 1
    }
    for item in array(corpusObject?["english_to_chinese"]) {
      let primary = item["primary"] as? String ?? ""
      let subtitle = item["subtitle"] as? String ?? ""
      try check(lexicon.meaning(.english, primary) == .ready(subtitle), "English corpus \(primary)")
      try check(lexicon.meaning(.english, primary.uppercased()) == .ready(subtitle), "English case \(primary)")
      reverse += 1
    }
    try check(forward >= 30 && reverse >= 30, "both directions have a frozen corpus")
    for item in array(corpusObject?["english_phrases"]) {
      let phrase = item["phrase"] as? String ?? ""
      let subtitle = item["subtitle"] as? String ?? ""
      try check(lexicon.storedPhrase(phrase) == subtitle, "phrase inventory \(phrase)")
      try check(lexicon.meaning(.english, phrase) == .ready(subtitle), "exact phrase lookup \(phrase)")
    }
    try check(lexicon.meaning(.english, "input") != lexicon.meaning(.english, "input method"),
              "single-token lookup does not return the phrase translation")
    for word in corpusObject?["chinese_misses"] as? [String] ?? [] {
      try check(lexicon.meaning(.chinese, word) == .missing, "Chinese miss \(word)")
    }
    for word in corpusObject?["english_misses"] as? [String] ?? [] {
      try check(lexicon.meaning(.english, word) == .missing, "English miss \(word)")
    }
    try check(lexicon.meaning(.chinese, "不是词xyz") == .missing, "unknown Chinese word is a miss")
    try check(lexicon.storedEnglish("studies") == "学业" && lexicon.meaning(.english, "studies") == .ready("学业"),
              "exact English headword wins over inflection")
    try check(lexicon.storedEnglish("cats") == nil && lexicon.meaning(.english, "cats") == lexicon.meaning(.english, "cat"),
              "regular English plural falls back to the stored singular")

    let commented = candidate("不是词xyz", comment: "hello", preview: "不是词xyz")
    try check(lexicon.meaning(.chinese, commented.candidates[0].descriptor.primary) == .missing,
              "engine comment is not used as a translation")
    let state = CompositionSession()
    state.activate()
    let whole = state.replace(direction: .chinese, rawInput: "nihao", preedit: "ni hao",
                              candidates: [CandidateDescriptor(primary: "你好", engineComment: "engine-note", label: "1", fullCommitPreview: "你好")],
                              highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    let ready = state.applySubtitles(lexicon.lookup(whole), for: whole.token)!
    try check(ready.candidates[0].descriptor.engineComment == "engine-note", "engine comment remains separate")
    try check(ready.highlighted == whole.highlighted && ready.page == whole.page && ready.token == whole.token,
              "dictionary refresh preserves identity page and highlight")
    try check(state.translatedText(for: ready.candidates[0].id) == "hello", "ready Chinese subtitle commits its displayed text")
    let host = FakeHost()
    try check(CommitCoordinator().commit("hello", expected: ready.token, state: state, host: host) && host.inserts == ["hello"],
              "translated commit inserts the displayed subtitle once")
    try check(state.applySubtitles(lexicon.lookup(whole), for: whole.token) == nil, "lookup after commit is rejected")

    state.activate()
    let partial = state.replace(direction: .chinese, rawInput: "nihao", preedit: "ni hao",
                                candidates: [CandidateDescriptor(primary: "你好", engineComment: "", label: "1", fullCommitPreview: nil)],
                                highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    _ = state.applySubtitles(lexicon.lookup(partial), for: partial.token)
    try check(state.snapshot?.candidates[0].subtitle == .ready("hello") && state.translatedText(for: partial.candidates[0].id) == nil,
              "partial candidate can display a subtitle but cannot commit it")

    state.activate()
    let blocked = LocalLexicon()
    blocked.suspendUntilLoaded()
    let pending = state.replace(direction: .english, rawInput: "hello", preedit: "hello",
                                candidates: [CandidateDescriptor(primary: "hello", engineComment: "", label: "", fullCommitPreview: "hello")],
                                highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    try check(blocked.lookup(pending, timeout: 0.05) == .unavailable, "lookup timeout is unavailable rather than a miss")
    try check(state.applySubtitles(.unavailable, for: pending.token)?.candidates[0].subtitle == .failed,
              "timeout displays failure rather than no-entry")
    try check(state.translatedText(for: pending.candidates[0].id) == nil, "failed subtitle cannot commit")
    let rawHost = FakeHost()
    try check(CommitCoordinator().commit("hello", expected: state.token, state: state, host: rawHost) && rawHost.inserts == ["hello"],
              "primary commit still works when translation is unavailable")
    try check(blocked.loadSynchronously(from: index), "lexicon becomes ready after the timeout")
    state.activate()
    let after = state.replace(direction: .english, rawInput: "hello", preedit: "hello",
                              candidates: [CandidateDescriptor(primary: "HELLO", engineComment: "", label: "", fullCommitPreview: "HELLO")],
                              highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    try check(state.applySubtitles(blocked.lookup(after, timeout: 0.05), for: after.token)?.candidates[0].subtitle == .ready("你好"),
              "timeout is not cached as a dictionary miss")

    let coordinator = TranslationCoordinator()
    let stale = coordinator.begin()
    let current = coordinator.begin()
    try check(coordinator.lookup(after, lexicon: lexicon, request: stale) == nil, "older lookup cannot overtake a newer request")
    if case .resolved(let values) = coordinator.lookup(after, lexicon: lexicon, request: current) {
      try check(values[after.candidates[0].id] == "你好", "current lookup still resolves")
    } else {
      try check(false, "current lookup still resolves")
    }
    coordinator.cancel()
    try check(coordinator.lookup(after, lexicon: lexicon, request: current) == nil, "cancelled lookup is not applied")

    try check(lexicon.meaning(.chinese, "中文") == .ready("Chinese") && lexicon.storedEnglish("chinese") != "中文",
              "Chinese-to-English is not produced by reversing the English index")
    try check(lexicon.meaning(.chinese, "时间") == .ready("time") && lexicon.meaning(.english, "time") == .ready("时候"),
              "English-to-Chinese is not produced by reversing the Chinese subtitles")

    var samples: [Double] = []
    let keys = lexicon.benchmarkChineseKeys(limit: 1000)
    for key in keys {
      let start = clock.now
      _ = lexicon.meaning(.chinese, key)
      samples.append(milliseconds(start.duration(to: clock.now)))
    }
    for _ in 0..<300 {
      let start = clock.now
      _ = lexicon.meaning(.chinese, "你好")
      samples.append(milliseconds(start.duration(to: clock.now)))
    }
    let sorted = samples.sorted()
    let maxSample = sorted.last ?? 0
    try check(maxSample < 20, "warm local lookup stays within the in-process bound")
    return [
      "status": "PASS",
      "check_count": checks.count,
      "checks": checks,
      "cold_load_ms": loadMs,
      "lookup_count": samples.count,
      "lookup_min_ms": sorted.first ?? 0,
      "lookup_p50_ms": percentile(sorted, 0.50),
      "lookup_p95_ms": percentile(sorted, 0.95),
      "lookup_max_ms": maxSample,
      "english_headwords": counts.english,
      "english_phrases": counts.phrases,
      "chinese_entries": counts.chinese,
      "directions_independent": true,
      "visible_panel_latency": "NOT_RUN",
      "scope": "in-process dictionary lookup, not installed IMK rendering"
    ]
  }

  static func candidate(_ primary: String, comment: String, preview: String?) -> CandidateSnapshot {
    let state = CompositionSession()
    state.activate()
    return state.replace(direction: .chinese, rawInput: primary, preedit: primary,
                         candidates: [CandidateDescriptor(primary: primary, engineComment: comment, label: "", fullCommitPreview: preview)],
                         highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
  }

  static func array(_ value: Any?) -> [[String: Any]] {
    value as? [[String: Any]] ?? []
  }

  static func int(_ value: Any?) -> Int? {
    if let number = value as? Int { return number }
    if let number = value as? NSNumber { return number.intValue }
    return nil
  }

  static func milliseconds(_ duration: Duration) -> Double {
    let parts = duration.components
    return Double(parts.seconds) * 1000 + Double(parts.attoseconds) / 1e15
  }

  static func percentile(_ sorted: [Double], _ fraction: Double) -> Double {
    guard !sorted.isEmpty else { return 0 }
    let index = min(sorted.count - 1, Int((Double(sorted.count - 1) * fraction).rounded(.down)))
    return sorted[index]
  }
}
