// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit

private enum CheckError: Error { case failed(String) }

private final class FakeHost: CommitHost {
  var inserts: [String] = []
  var succeeds = true
  var onInsert: (() -> Void)?
  func insert(_ text: String) -> Bool {
    inserts.append(text)
    onInsert?()
    return succeeds
  }
}

private final class FakeModeHost: CompositionModeHost {
  let state = CompositionSession()
  var modeASCII = false
  var raw = ""
  var inserts: [String] = []
  var onInsert: (() -> Void)?
  var rightTaps = 0
  var refreshes = 0
  var modeToken: CompositionToken { state.token }
  var modeActive: Bool { state.active }
  var modeHasEnglishInput: Bool { !state.englishInput.isEmpty }
  func modeFinalizeRaw() -> Bool {
    let text = state.englishInput.isEmpty ? raw : state.englishInput
    raw = ""
    if text.isEmpty { return state.active }
    return CommitCoordinator().commit(text, expected: state.token, state: state, host: ClosureCommitHost { text in
      self.inserts.append(text); self.onInsert?(); return true
    })
  }
  func modeSetASCII(_ enabled: Bool) { modeASCII = enabled }
  func modeRightShiftTap(modifiers: UInt) { rightTaps += 1; modeASCII.toggle() }
  func modeRefresh() { refreshes += 1 }
}

@main
struct Round1Checks {
  static var checks: [String] = []
  static func check(_ condition: @autoclosure () -> Bool, _ name: String) throws {
    guard condition() else { throw CheckError.failed(name) }
    checks.append(name)
  }

  static func snapshot(_ state: CompositionSession, raw: String = "nihao", page: Int = 0,
                       highlighted: Int = 0, fullPreview: String? = "你好") -> CandidateSnapshot {
    state.replace(direction: .chinese, rawInput: raw, preedit: "ni hao",
                  candidates: [CandidateDescriptor(primary: "你好", engineComment: "engine-note", label: "1", fullCommitPreview: fullPreview),
                               CandidateDescriptor(primary: "世界", engineComment: "", label: "2", fullCommitPreview: nil)],
                  highlighted: highlighted, page: page, lastPage: false, examplesEnabled: true)!
  }

  static func policy(_ code: UInt16, text: String? = nil, composing: Bool = true,
                     english: String = "", enabled: Bool = false,
                     option: Bool = false, command: Bool = false) -> CompositionKeyAction {
    CompositionKeyPolicy.action(keyCode: code, text: text, command: command, control: false,
                                option: option, shift: false, hasComposition: composing,
                                englishInput: english, englishEnabled: enabled)
  }

  static func main() {
    do {
      try run()
      let report: [String: Any] = ["status": "PASS", "check_count": checks.count, "checks": checks,
                                 "scope": "shared key policy/state/commit and layout; fake host, not installed IMK acceptance"]
      let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
      print(String(decoding: data, as: UTF8.self))
    } catch {
      fputs("Round 1 checks failed: \(error)\n", stderr)
      exit(1)
    }
  }

  static func run() throws {
    try shiftRouting()
    try check(policy(49) == .engine, "Chinese Space delegates selection to engine")
    try check(policy(18, text: "1") == .engine, "Chinese digit retains engine labels/recognizers")
    try check(policy(36) == .raw, "composing Return submits raw input")
    try check(policy(76) == .raw, "keypad Enter shares raw contract")
    try check(policy(36, composing: false) == .host, "empty Return reaches host")
    try check(policy(53) == .cancel, "composing Escape cancels")
    try check(policy(53, composing: false) == .engine, "empty Escape retains engine/host fallback")
    try check(policy(36, option: true) == .translated, "Option Return targets translated commit")
    try check(policy(36, composing: false, option: true) == .host, "empty Option Return reaches host")
    try check(policy(48) == .rawThenHost, "Tab finalizes raw then passes through")
    try check(policy(0, command: true) == .rawThenHost, "Command shortcuts invalidate/finalize then pass")
    try check(policy(49, english: "hello", enabled: true) == .englishSpace, "English Space preserves separator")
    try check(policy(18, text: "1", english: "hello", enabled: true) == .englishText("1"), "English digit appends literal")
    try check(policy(18, text: "1", composing: false, enabled: true) == .rawThenHost, "initial English digit reaches host")
    try check(policy(51, english: "hello", enabled: true) == .englishBackspace, "English Backspace edits token")
    try check(policy(47, text: ".", english: "hello", enabled: true) == .rawThenHost, "English punctuation finalizes without conversion")
    try check(policy(0, text: "a", enabled: false) == .engine, "Example Off retains direct engine handling")

    let state = CompositionSession()
    state.activate()
    let first = snapshot(state)
    try check(state.translatedText(for: first.candidates[0].id) == nil, "pending example cannot insert")
    let ready = state.applyExamples(ExampleTranslation.results(for: first), for: first.token)!
    try check(state.translatedText(for: ready.candidates[0].id) == "hello", "ready whole candidate resolves example")
    try check(state.translatedText(for: ready.candidates[1].id) == nil, "display-only segment cannot translate commit")
    try check(ready.candidates[0].descriptor.engineComment == "engine-note", "engine comments separate from example")
    try check(ready.token == first.token && ready.page == first.page && ready.highlighted == first.highlighted,
              "example refresh preserves identity page and highlight")
    let unchanged = snapshot(state)
    try check(unchanged == ready, "identical UI refresh retains ready example")
    let host = FakeHost()
    let commits = CommitCoordinator()
    try check(commits.commit("hello", expected: ready.token, state: state, host: host), "translated commit inserts once")
    try check(!commits.commit("nihao", expected: ready.token, state: state, host: host), "deactivation cannot append old original")
    try check(host.inserts == ["hello"], "exact translated output without original")
    try check(state.applyExamples(ExampleTranslation.results(for: first), for: first.token) == nil, "callback after commit rejected")

    let old = snapshot(state)
    _ = snapshot(state, raw: "niha", page: 1, highlighted: 1)
    try check(state.candidate(old.candidates[0].id) == nil, "old mouse/keyboard identity rejected after input/page")
    try check(state.applyExamples(ExampleTranslation.results(for: old), for: old.token) == nil, "out of order example rejected")
    let oldField = snapshot(state)
    state.deactivate(); state.activate()
    _ = snapshot(state)
    try check(state.applyExamples(ExampleTranslation.results(for: oldField), for: oldField.token) == nil, "same word in new field rejects old generation")
    let unsafe = snapshot(state, fullPreview: "你好zhongguo")
    _ = state.applyExamples(ExampleTranslation.results(for: unsafe), for: unsafe.token)
    try check(state.translatedText(for: unsafe.candidates[0].id) == nil, "partial composition preview blocks translated insertion")
    let failure = snapshot(state)
    let failedHost = FakeHost(); failedHost.succeeds = false
    try check(!commits.commit("你好", expected: failure.token, state: state, host: failedHost), "host failure surfaced")
    try check(!commits.commit("你好", expected: failure.token, state: state, host: failedHost) && failedHost.inserts.count == 1,
              "uncertain host insertion never retried")
    let reentrant = snapshot(state)
    let reentrantHost = FakeHost()
    reentrantHost.onInsert = { state.deactivate() }
    try check(commits.commit("你好", expected: reentrant.token, state: state, host: reentrantHost), "reentrant focus loss sees invalidated state")
    try check(state.snapshot == nil && reentrantHost.inserts == ["你好"], "reentrant insert produces no duplicate")
    try check(!commits.commit("x", expected: state.token, state: state, host: host), "inactive client commit rejected")

    state.activate()
    try check(state.appendEnglish("hello"), "English buffer starts token")
    state.backspaceEnglish()
    try check(state.englishInput == "hell", "English buffer backspace")
    let english = state.replace(direction: .english, rawInput: state.englishInput, preedit: state.englishInput,
                                candidates: [CandidateDescriptor(primary: "hell", engineComment: "", label: "", fullCommitPreview: "hell")],
                                highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    _ = state.applyExamples(ExampleTranslation.results(for: english), for: english.token)
    try check(state.snapshot?.highlightedCandidate?.subtitle == .missing, "unknown token has no fabricated translation")
    state.invalidate()
    try check(state.appendEnglish(String(repeating: "a", count: 256)) && !state.appendEnglish("b"), "English composition length bounded")
    state.invalidate()
    try check(state.appendEnglish("HELLO"), "uppercase English primary preserved")
    let enFixture = state.replace(direction: .english, rawInput: "HELLO", preedit: "HELLO",
                                 candidates: [CandidateDescriptor(primary: "HELLO", engineComment: "", label: "", fullCommitPreview: "HELLO")],
                                 highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
    let enReady = state.applyExamples(ExampleTranslation.results(for: enFixture), for: enFixture.token)!
    try check(state.translatedText(for: enReady.candidates[0].id) == "你好", "English ready fixture resolves Chinese translation")
    let enHost = FakeHost()
    try check(commits.commit("你好", expected: enReady.token, state: state, host: enHost), "English translated commit accepted")
    state.deactivate()
    try check(!commits.commit("HELLO", expected: enReady.token, state: state, host: enHost) && enHost.inserts == ["你好"],
              "English translated commit then focus loss cannot append original")
    state.activate()
    let beforeOff = snapshot(state)
    _ = state.replace(direction: .chinese, rawInput: "nihao", preedit: "ni hao",
                      candidates: beforeOff.candidates.map(\.descriptor), highlighted: 0, page: 0,
                      lastPage: false, examplesEnabled: false)
    try check(state.applyExamples(ExampleTranslation.results(for: beforeOff), for: beforeOff.token) == nil &&
              state.snapshot?.highlightedCandidate?.subtitle == .off, "turning examples off rejects queued result")
    state.invalidate()
    let textSnapshot = snapshot(state)
    let font = NSFont.systemFont(ofSize: 17)
    let layout = BilingualCandidateLayout(snapshot: textSnapshot, maximumWidth: 400, font: font)
    try check(layout.cells.count == 2 && layout.cells[0].minY == layout.cells[1].minY && layout.cells[0].maxX < layout.cells[1].minX,
              "candidate columns are horizontal and separated")
    try check(layout.candidateIndex(at: NSPoint(x: layout.cells[1].midX, y: layout.cells[1].maxY - 5)) == 1,
              "subtitle hit selects its own column")
    let narrow = BilingualCandidateLayout(snapshot: textSnapshot, maximumWidth: 120, font: font)
    try check(narrow.size.width <= 120 && narrow.cells.last!.maxX <= 120, "narrow panel stays inside width budget")
    let screen = NSRect(x: -1200, y: -200, width: 1200, height: 800)
    let panel = BilingualCandidateLayout.panelFrame(size: layout.size, caret: NSRect(x: -5, y: -195, width: 1, height: 18), screen: screen)
    try check(screen.contains(panel), "negative origin screen edge placement clamped")
    let topPanel = BilingualCandidateLayout.panelFrame(size: layout.size, caret: NSRect(x: -1195, y: 580, width: 1, height: 18), screen: screen)
    try check(screen.contains(topPanel), "top edge panel placement clamped")

    if CommandLine.arguments.count == 2 {
      let target = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
      try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
      let zh = state.applyExamples(ExampleTranslation.results(for: textSnapshot), for: textSnapshot.token)!
      try render(zh, name: "chinese-examples.png", target: target)
      state.invalidate()
      let en = state.replace(direction: .english, rawInput: "hello", preedit: "hello",
                             candidates: [CandidateDescriptor(primary: "hello", engineComment: "", label: "", fullCommitPreview: "hello")],
                             highlighted: 0, page: 0, lastPage: true, examplesEnabled: true)!
      let enReady = state.applyExamples(ExampleTranslation.results(for: en), for: en.token)!
      try render(enReady, name: "english-examples.png", target: target)
    }
  }

  static func shiftRouting() throws {
    let host = FakeModeHost()
    let router = CompositionModeRouter()
    host.state.activate(); host.raw = "nihao"
    func flags(_ key: UInt16, _ modifiers: UInt, _ timestamp: Double) {
      _ = router.handleModifiers(ShiftModifierEvent(keyCode: key, modifiers: modifiers, timestamp: timestamp), host: host)
    }
    flags(56, ShiftModifierEvent.shiftMask, 1); flags(56, 0, 1.1)
    try check(host.modeASCII && host.inserts == ["nihao"] && host.raw.isEmpty, "left tap finalizes Chinese raw before mode change")
    _ = host.state.appendEnglish("HELLO")
    flags(60, ShiftModifierEvent.shiftMask, 2); router.keyDown(modifiers: ShiftModifierEvent.shiftMask); flags(60, 0, 2.1)
    try check(host.modeASCII && host.state.englishInput == "HELLO" && host.rightTaps == 0, "right Shift typing cannot replay a mode tap")
    flags(60, ShiftModifierEvent.shiftMask, 3); flags(60, 0, 3.1)
    try check(!host.modeASCII && host.inserts == ["nihao", "HELLO"] && host.rightTaps == 1, "right tap finalizes frontend English before schema replay")
    flags(56, ShiftModifierEvent.shiftMask, 4); flags(56, 0, 4.8)
    try check(!host.modeASCII, "long Shift hold does not become a mode tap")
    flags(56, ShiftModifierEvent.shiftMask, 5); router.reset(); flags(56, 0, 5.1)
    try check(!host.modeASCII, "focus reset rejects old Shift release")
    host.modeASCII = true; _ = host.state.appendEnglish("hello")
    host.onInsert = { host.state.deactivate(); host.state.activate(); router.reset() }
    flags(60, ShiftModifierEvent.shiftMask, 6); flags(60, 0, 6.1)
    try check(host.modeASCII && host.rightTaps == 1 && host.inserts.last == "hello", "reentrant focus change stops mode replay without duplicate commit")
    host.onInsert = { host.state.invalidate(); router.reset() }
    _ = host.state.appendEnglish("world")
    flags(56, ShiftModifierEvent.shiftMask, 7); flags(56, 0, 7.1)
    try check(host.modeASCII && host.inserts.last == "world", "reentrant cancellation stops mode change after raw reservation")
    flags(60, ShiftModifierEvent.shiftMask, 8); flags(60, ShiftModifierEvent.shiftMask, 8.01)
    try check(host.modeASCII && host.rightTaps == 1, "duplicate Shift press does not toggle before release")
    flags(60, 0, 8.1)
    try check(!host.modeASCII && host.rightTaps == 2, "duplicate Shift press still yields one tap on release")
    flags(56, ShiftModifierEvent.shiftMask | ShiftModifierEvent.leftDeviceMask, 9)
    flags(56, ShiftModifierEvent.shiftMask | ShiftModifierEvent.leftDeviceMask, 9.04)
    flags(56, ShiftModifierEvent.shiftMask, 9.08)
    flags(56, 0, 9.16)
    try check(host.modeASCII, "left Shift tap survives repeated flags and a dropped device bit")
    host.onInsert = nil
    flags(56, ShiftModifierEvent.shiftMask, 10)
    flags(0, ShiftModifierEvent.shiftMask, 10.02)
    flags(0, 0, 10.1)
    try check(!host.modeASCII, "anonymous repeated Shift flags preserve the pending left tap")
    let rightTaps = host.rightTaps
    flags(60, ShiftModifierEvent.shiftMask, 11); flags(0, 0, 11.1)
    try check(host.modeASCII && host.rightTaps == rightTaps + 1, "anonymous release retains the known right Shift binding")
    flags(0, ShiftModifierEvent.shiftMask | ShiftModifierEvent.rightDeviceMask, 12)
    flags(0, ShiftModifierEvent.shiftMask | ShiftModifierEvent.rightDeviceMask, 12.02)
    flags(0, 0, 12.1)
    try check(!host.modeASCII && host.rightTaps == rightTaps + 2, "device flags identify an entirely anonymous right tap")
    flags(56, ShiftModifierEvent.shiftMask, 13)
    router.keyDown(modifiers: 0) // Missing release, then an ordinary typed key.
    flags(56, ShiftModifierEvent.shiftMask, 13.2); flags(56, 0, 13.3)
    try check(host.modeASCII, "unshifted key recovers a missing release before the next tap")
    flags(0, ShiftModifierEvent.shiftMask, 14)
    flags(0, ShiftModifierEvent.shiftMask | (1 << 19), 14.01)
    flags(0, ShiftModifierEvent.shiftMask, 14.02); flags(0, 0, 14.1)
    try check(host.modeASCII, "anonymous Option chord cannot become a Shift tap")
    flags(0, ShiftModifierEvent.shiftMask | 0x6, 15); flags(0, 0, 15.1)
    try check(host.modeASCII, "anonymous simultaneous Shift changes cannot invent a tap")
    flags(56, ShiftModifierEvent.shiftMask, 15.2); flags(56, 0, 15.3)
    try check(!host.modeASCII, "a fresh tap recovers after ambiguous aggregate releases")
    try check(router.setASCII(true, host: host), "explicit selection restores English after overlap")
    let current = host.state.token
    _ = host.state.appendEnglish("hello")
    let composing = host.state.token
    let insertionCount = host.inserts.count
    try check(router.setASCII(true, host: host) && host.state.token == composing && host.inserts.count == insertionCount,
              "selecting the current language preserves pending input")
    try check(router.setASCII(false, host: host) && host.inserts.last == "hello" && host.state.englishInput.isEmpty,
              "explicit language selection finalizes raw exactly once")
    try check(host.state.token != current, "explicit mode handoff retires prior composition")
    host.raw = "nihao"
    host.onInsert = { host.state.deactivate(); host.state.activate() }
    try check(!router.setASCII(true, host: host) && !host.modeASCII && host.inserts.last == "nihao",
              "explicit mode selection cannot change a reentrantly replaced focus")
    host.onInsert = nil
    host.state.deactivate()
    try check(!router.setASCII(true, host: host), "inactive menu or CLI cannot switch a stale controller")
    try check(!CompositionModeRouter.usesEnglishComposer(ascii: true, examples: true, engineInput: "nihao"), "inline ASCII with a live engine prefix cannot start a second buffer")
    try check(CompositionModeRouter.usesEnglishComposer(ascii: true, examples: true, engineInput: ""), "empty engine permits frontend English composition")
  }

  static func render(_ snapshot: CandidateSnapshot, name: String, target: URL) throws {
    let font = NSFont.systemFont(ofSize: 17)
    let layout = BilingualCandidateLayout(snapshot: snapshot, maximumWidth: 800, font: font)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(layout.size.width * 2),
                                  pixelsHigh: Int(layout.size.height * 2), bitsPerSample: 8,
                                  samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let bitmapContext = NSGraphicsContext(bitmapImageRep: bitmap)!
    let cg = bitmapContext.cgContext
    cg.scaleBy(x: 2, y: 2)
    cg.translateBy(x: 0, y: layout.size.height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
    BilingualCandidateRenderer.draw(snapshot: snapshot, layout: layout, highlighted: snapshot.highlighted,
                                    font: font, background: .windowBackgroundColor)
    NSGraphicsContext.restoreGraphicsState()
    let data = bitmap.representation(using: .png, properties: [:])!
    try data.write(to: target.appendingPathComponent(name), options: .withoutOverwriting)
  }
}
