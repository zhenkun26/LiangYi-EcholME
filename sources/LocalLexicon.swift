// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

// Offline CC-CEDICT index. The file is CC-BY-SA-4.0 data; this loader is GPL.
// Lookup receives copied candidate text only. It never sees a host client,
// engine comment, credential, or surrounding field.
final class LocalLexicon: @unchecked Sendable {
  static let shared = LocalLexicon()
  static let lookupBudget: TimeInterval = 0.15
  private static let cacheLimit = 512

  private let state = NSCondition()
  private var phase: Phase = .idle
  private var chinese: [String: String] = [:]
  private var english: [String: String] = [:]
  private var phrases: [String: String] = [:]
  private var revision = ""
  private var singleCharacters = 0
  private var cache: [CacheKey: CacheValue] = [:]
  private var cacheOrder: [CacheKey] = []

  private enum Phase { case idle, loading, ready, failed }
  private struct CacheKey: Hashable { let revision, direction, text: String }
  private enum CacheValue {
    case ready(String), missing
    var subtitle: ExampleSubtitle {
      switch self {
      case .ready(let text): return .ready(text)
      case .missing: return .missing
      }
    }
  }

  var isReady: Bool {
    state.lock(); defer { state.unlock() }
    return phase == .ready
  }

  var counts: (chinese: Int, english: Int, phrases: Int, singleCharacters: Int) {
    state.lock(); defer { state.unlock() }
    return (chinese.count, english.count, phrases.count, singleCharacters)
  }

  func startLoading(from url: URL, completion: @escaping (Bool) -> Void) {
    state.lock()
    if phase != .idle {
      let ready = phase == .ready
      state.unlock()
      completion(ready)
      return
    }
    phase = .loading
    state.unlock()
    DispatchQueue.global(qos: .userInitiated).async {
      let loaded = self.loadSynchronously(from: url)
      DispatchQueue.main.async { completion(loaded) }
    }
  }

  @discardableResult
  func loadSynchronously(from url: URL) -> Bool {
    let parsed = Self.parse(url)
    state.lock()
    if let parsed {
      chinese = parsed.chinese
      english = parsed.english
      phrases = parsed.phrases
      revision = parsed.revision
      singleCharacters = parsed.chinese.keys.reduce(into: 0) { count, key in
        if key.count == 1 { count += 1 }
      }
      cache.removeAll()
      cacheOrder.removeAll()
      phase = .ready
    } else {
      phase = .failed
    }
    state.broadcast()
    state.unlock()
    return parsed != nil
  }

  func suspendUntilLoaded() {
    state.lock()
    phase = .loading
    state.unlock()
  }

  func failLoading() {
    state.lock()
    phase = .failed
    state.broadcast()
    state.unlock()
  }

  func lookup(_ snapshot: CandidateSnapshot, timeout: TimeInterval = lookupBudget) -> SubtitleDelivery {
    guard waitUntilReady(timeout: timeout) else { return .unavailable }
    var resolved: [CandidateIdentity: String] = [:]
    for candidate in snapshot.candidates {
      // Engine comments are not translations. Only the candidate's own text is read.
      if case .ready(let text) = meaning(snapshot.direction, candidate.descriptor.primary) {
        resolved[candidate.id] = text
      }
    }
    return .resolved(resolved)
  }

  func meaning(_ direction: InputDirection, _ primary: String) -> ExampleSubtitle {
    state.lock()
    defer { state.unlock() }
    guard phase == .ready else { return .failed }
    let key = CacheKey(revision: revision, direction: direction.rawValue, text: primary)
    if let cached = cache[key] {
      return cached.subtitle
    }
    let status = uncached(direction, primary)
    remember(key, status)
    return status.subtitle
  }

  func storedEnglish(_ primary: String) -> String? {
    state.lock(); defer { state.unlock() }
    return english[primary.lowercased()]
  }

  func storedPhrase(_ primary: String) -> String? {
    state.lock(); defer { state.unlock() }
    return phrases[primary.lowercased()]
  }

  func benchmarkChineseKeys(limit: Int) -> [String] {
    state.lock(); defer { state.unlock() }
    return Array(chinese.keys.prefix(max(0, limit)))
  }

  private func uncached(_ direction: InputDirection, _ primary: String) -> CacheValue {
    switch direction {
    case .chinese:
      guard let text = chinese[primary], !text.isEmpty else { return .missing }
      return .ready(text)
    case .english:
      let key = primary.lowercased()
      if key.contains(" ") {
        guard let text = phrases[key], !text.isEmpty else { return .missing }
        return .ready(text)
      }
      if let text = english[key], !text.isEmpty { return .ready(text) }
      for stem in Self.stems(key) {
        if let text = english[stem], !text.isEmpty { return .ready(text) }
      }
      return .missing
    }
  }

  private func remember(_ key: CacheKey, _ value: CacheValue) {
    cache[key] = value
    cacheOrder.append(key)
    if cacheOrder.count > Self.cacheLimit {
      cache.removeValue(forKey: cacheOrder.removeFirst())
    }
  }

  private func waitUntilReady(timeout: TimeInterval) -> Bool {
    state.lock()
    if phase == .ready {
      state.unlock()
      return true
    }
    if phase == .failed {
      state.unlock()
      return false
    }
    let deadline = Date().addingTimeInterval(timeout)
    while phase == .idle || phase == .loading {
      if !state.wait(until: deadline), phase == .idle || phase == .loading {
        state.unlock()
        return false
      }
    }
    let ready = phase == .ready
    state.unlock()
    return ready
  }

  private static func stems(_ word: String) -> [String] {
    guard word.count >= 4, word.unicodeScalars.allSatisfy({ CharacterSet.lowercaseLetters.contains($0) || $0 == "'" }) else {
      return []
    }
    var found: [String] = []
    func add(_ stem: String) {
      let trimmed = stem.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
      if trimmed.count >= 3 { found.append(trimmed) }
    }
    if word.hasSuffix("ies"), word.count >= 5 { add(String(word.dropLast(3)) + "y") }
    if word.hasSuffix("ing"), word.count >= 6 {
      let base = String(word.dropLast(3))
      add(base)
      add(base + "e")
      if base.count >= 4, let last = base.last, base.dropLast().last == last { add(String(base.dropLast())) }
    }
    if word.hasSuffix("ed"), word.count >= 5 {
      let base = String(word.dropLast(2))
      add(base)
      add(base + "e")
      if base.count >= 4, let last = base.last, base.dropLast().last == last { add(String(base.dropLast())) }
    }
    if word.hasSuffix("es"), word.count >= 4, !word.hasSuffix("ss") {
      add(String(word.dropLast(2)))
    } else if word.hasSuffix("s"), word.count >= 4, !word.hasSuffix("ss") {
      add(String(word.dropLast()))
    }
    return found
  }

  private struct Parsed {
    let revision: String
    let chinese, english, phrases: [String: String]
  }

  private static func parse(_ url: URL) -> Parsed? {
    guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    if lines.last?.isEmpty == true { lines.removeLast() }
    guard lines.count >= 5, lines[0] == "LYLX1", lines[1].count == 64,
          lines[1].allSatisfy({ $0.isHexDigit }) else { return nil }
    var cursor = 2
    func section(_ tag: String) -> [String: String]? {
      guard cursor < lines.count else { return nil }
      let header = lines[cursor].split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
      cursor += 1
      guard header.count == 2, header[0] == tag, let count = Int(header[1]), count >= 0 else { return nil }
      var map: [String: String] = [:]
      map.reserveCapacity(count)
      for _ in 0..<count {
        guard cursor < lines.count else { return nil }
        let fields = lines[cursor].split(separator: "\t", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
        cursor += 1
        guard fields.count == 2, !fields[0].isEmpty, !fields[1].isEmpty,
              !fields[1].contains("\t"), !fields[1].contains(where: \.isNewline) else { return nil }
        if map.updateValue(fields[1], forKey: fields[0]) != nil { return nil }
      }
      return map
    }
    guard let chinese = section("ZH"), let english = section("EN"), let phrases = section("PH"),
          cursor == lines.count else { return nil }
    return Parsed(revision: lines[1], chinese: chinese, english: english, phrases: phrases)
  }
}

final class TranslationCoordinator: @unchecked Sendable {
  private let lock = NSLock()
  private var current: UInt64 = 0

  func begin() -> UInt64 {
    lock.lock(); defer { lock.unlock() }
    current &+= 1
    return current
  }

  func cancel() { _ = begin() }

  func isCurrent(_ request: UInt64) -> Bool {
    lock.lock(); defer { lock.unlock() }
    return request == current
  }

  func lookup(_ snapshot: CandidateSnapshot, lexicon: LocalLexicon, request: UInt64,
              timeout: TimeInterval = LocalLexicon.lookupBudget) -> SubtitleDelivery? {
    let delivery = lexicon.lookup(snapshot, timeout: timeout)
    return isCurrent(request) ? delivery : nil
  }
}
