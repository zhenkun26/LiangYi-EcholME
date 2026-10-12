// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
// Shared production Shift router + pinned real librime + synthetic host.
// Called inside RimeSmoke's confined lifecycle; no IMK process/document access.

import AppKit

private enum ShiftCheckError: Error { case failed(String) }

private final class ShiftHarness: CompositionModeHost {
  let api = rime_get_api_stdbool().pointee
  let session: RimeSessionId
  let state = CompositionSession()
  let router = CompositionModeRouter()
  let commits = CommitCoordinator()
  var output: [String] = []
  var marked = ""
  var examples = true
  var insertSucceeds = true
  var onInsert: (() -> Void)?
  var rightTapCount = 0

  init(session: RimeSessionId) { self.session = session }
  var modeToken: CompositionToken { state.token }
  var modeActive: Bool { state.active }
  var modeASCII: Bool { api.get_option(session, "ascii_mode") }
  var modeHasEnglishInput: Bool { !state.englishInput.isEmpty }
  var raw: String { api.get_input(session).map { String(cString: $0) } ?? "" }

  func reset(ascii: Bool) {
    clearEngine()
    state.activate()
    router.reset()
    output = []; marked = ""; rightTapCount = 0
    examples = true; insertSucceeds = true; onInsert = nil
    api.set_option(session, "ascii_mode", ascii)
  }

  func clearEngine() {
    api.clear_composition(session)
    var value = RimeCommit.rimeStructInit()
    if api.get_commit(session, &value) { _ = api.free_commit(&value) }
  }

  @discardableResult
  func insert(_ text: String, expected: CompositionToken? = nil) -> Bool {
    let value = expected ?? state.token
    return commits.commit(text, expected: value, state: state, host: ClosureCommitHost { text in
      guard self.insertSucceeds else { return false }
      self.output.append(text)
      self.marked = ""
      self.onInsert?()
      return true
    })
  }

  func modeFinalizeRaw() -> Bool {
    guard state.active else { return false }
    let text = state.englishInput.isEmpty ? raw : state.englishInput
    let expected = state.token
    clearEngine()
    if !text.isEmpty { return insert(text, expected: expected) }
    return state.active && state.token == expected
  }
  func modeSetASCII(_ enabled: Bool) { api.set_option(session, "ascii_mode", enabled) }
  func modeRightShiftTap(modifiers: UInt) {
    rightTapCount += 1
    let base = SquirrelKeycode.osxModifiersToRime(modifiers: NSEvent.ModifierFlags(rawValue: modifiers))
    _ = api.process_key(session, XK_Shift_R, Int32(base | kShiftMask.rawValue))
    _ = api.process_key(session, XK_Shift_R, Int32(base | kReleaseMask.rawValue))
  }
  func modeRefresh() {
    guard state.active else { return }
    var commit = RimeCommit.rimeStructInit()
    if api.get_commit(session, &commit) {
      if let text = commit.text { insert(String(cString: text)) }
      _ = api.free_commit(&commit)
    }
    guard state.active else { return }
    if modeASCII, !state.englishInput.isEmpty { englishSnapshot(); return }
    var context = RimeContext_stdbool.rimeStructInit()
    guard api.get_context(session, &context) else { return }
    marked = context.composition.preedit.map { String(cString: $0) } ?? ""
    if raw.isEmpty { state.invalidate() }
    else {
      let first = context.menu.num_candidates > 0 ? context.menu.candidates[0].text.map { String(cString: $0) } : nil
      let values = first.map { [CandidateDescriptor(primary: $0, engineComment: "", label: "1", fullCommitPreview: nil)] } ?? []
      state.replace(direction: .chinese, rawInput: raw, preedit: marked, candidates: values,
                    highlighted: 0, page: 0, lastPage: true, examplesEnabled: examples)
    }
    _ = api.free_context(&context)
  }
  func englishSnapshot() {
    marked = state.englishInput
    state.replace(direction: .english, rawInput: marked, preedit: marked,
                  candidates: [CandidateDescriptor(primary: marked, engineComment: "", label: "", fullCommitPreview: marked)],
                  highlighted: 0, page: 0, lastPage: true, examplesEnabled: examples)
  }

  func flags(_ key: UInt16, _ modifiers: NSEvent.ModifierFlags, at time: Double) {
    let event = NSEvent.keyEvent(with: .flagsChanged, location: .zero, modifierFlags: modifiers,
                                timestamp: time, windowNumber: 0, context: nil,
                                characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: key)!
    let copied = ShiftModifierEvent(keyCode: event.keyCode, modifiers: event.modifierFlags.rawValue, timestamp: event.timestamp)
    if !router.handleModifiers(copied, host: self) {
      let code = SquirrelKeycode.osxKeycodeToRime(keycode: key, keychar: nil, shift: false, caps: false)
      _ = api.process_key(session, Int32(code), Int32(SquirrelKeycode.osxModifiersToRime(modifiers: modifiers)))
      modeRefresh()
    }
  }
  func tap(_ key: UInt16, at time: Double = 1) {
    flags(key, .shift, at: time)
    flags(key, [], at: time + 0.1)
  }
  func type(_ text: String, modifiers: NSEvent.ModifierFlags = []) {
    for letter in text { key(0, text: String(letter), modifiers: modifiers) }
  }
  func key(_ code: UInt16, text: String, modifiers: NSEvent.ModifierFlags = []) {
    router.keyDown()
    let action = CompositionKeyPolicy.action(keyCode: code, text: text,
      command: modifiers.contains(.command), control: modifiers.contains(.control),
      option: modifiers.contains(.option), shift: modifiers.contains(.shift),
      hasComposition: !state.englishInput.isEmpty || !raw.isEmpty, englishInput: state.englishInput,
      englishEnabled: CompositionModeRouter.usesEnglishComposer(ascii: modeASCII, examples: examples, engineInput: raw))
    switch action {
    case .englishText(let text):
      if state.appendEnglish(text) { englishSnapshot() }
    case .englishSpace: insert(state.englishInput + " ")
    case .englishBackspace:
      state.backspaceEnglish()
      if state.englishInput.isEmpty { state.invalidate(); marked = "" } else { englishSnapshot() }
    case .raw: _ = modeFinalizeRaw()
    case .cancel: clearEngine(); state.invalidate(); marked = ""
    case .rawThenHost:
      _ = modeFinalizeRaw()
      if code == 0 { output.append(text) }
    case .engine:
      let mapped = SquirrelKeycode.osxKeycodeToRime(keycode: code, keychar: text.first,
                          shift: modifiers.contains(.shift), caps: modifiers.contains(.capsLock))
      let handled = api.process_key(session, Int32(mapped), Int32(SquirrelKeycode.osxModifiersToRime(modifiers: modifiers)))
      modeRefresh()
      if !handled, code == 0 { output.append(text) }
    case .host: if code == 0 { output.append(text) }
    case .translated: break // Existing core tests cover translated selection.
    }
  }
}

private enum ShiftRegressions {
  static var checks: [String] = []
  static func check(_ condition: @autoclosure () -> Bool, _ name: String) throws {
    guard condition() else { throw ShiftCheckError.failed(name) }
    checks.append(name)
  }

  static func run(_ h: ShiftHarness) throws {
    // Negative controls establish both old engine conditions with the pinned
    // library, instead of assuming how its modifier/inline composer behaves.
    h.reset(ascii: false); h.type("nihao")
    _ = h.api.process_key(h.session, XK_Shift_L, Int32(kShiftMask.rawValue))
    _ = h.api.process_key(h.session, XK_Shift_L, Int32(kReleaseMask.rawValue))
    h.modeRefresh()
    try check(h.modeASCII && h.raw == "nihao", "real engine control: left inline ASCII retains Chinese raw prefix")
    h.key(0, text: "a")
    try check(h.raw == "nihaoa" && h.state.englishInput.isEmpty, "live inline prefix remains entirely engine-owned")
    h.key(36, text: "\r")
    try check(h.output == ["nihaoa"] && h.raw.isEmpty && h.marked.isEmpty, "inline ASCII raw Return preserves the entire prefix once")
    h.reset(ascii: false); h.type("nihao")
    _ = h.api.process_key(h.session, XK_Shift_L, Int32(kShiftMask.rawValue))
    _ = h.api.process_key(h.session, XK_Shift_L, Int32(kReleaseMask.rawValue))
    h.modeRefresh(); h.tap(60)
    try check(!h.modeASCII && h.raw.isEmpty && h.output == ["nihao"], "right tap lets Rime finalize its own inline prefix without a double mode toggle")

    h.reset(ascii: true)
    _ = h.api.process_key(h.session, XK_Shift_R, Int32(kShiftMask.rawValue))
    _ = h.state.appendEnglish("A")
    _ = h.api.process_key(h.session, XK_Shift_R, Int32(kReleaseMask.rawValue))
    try check(!h.modeASCII, "real engine control: missing intervening letter makes right Shift look like a tap")

    h.reset(ascii: false); h.type("nihao")
    let obsolete = h.state.token
    h.tap(56)
    try check(h.output == ["nihao"] && h.modeASCII && h.raw.isEmpty, "P1 left tap finalizes Chinese raw before English starts")
    h.type("a"); h.key(36, text: "\r")
    try check(h.output == ["nihao", "a"] && h.marked.isEmpty && h.raw.isEmpty, "P1 nihao left Shift a Return loses no input or separator")
    try check(h.state.applyExamples([:], for: obsolete) == nil, "mode switch invalidates old Chinese examples")
    h.modeRefresh()
    try check(h.output == ["nihao", "a"] && h.state.englishInput.isEmpty, "post-switch refresh cannot append or resurrect old input")

    for key: UInt16 in [56, 60] {
      h.reset(ascii: true)
      h.flags(key, .shift, at: 2); h.type("HELLO", modifiers: .shift); h.flags(key, [], at: 2.1)
      try check(h.modeASCII && h.state.englishInput == "HELLO" && h.marked == "HELLO", "Shift \(key) uppercase release keeps English token and mode")
      h.key(49, text: " ")
      try check(h.output == ["HELLO "] && h.raw.isEmpty && h.marked.isEmpty, "Shift \(key) uppercase Space commits once")
      h.reset(ascii: true); h.type("hello"); h.tap(key)
      try check(!h.modeASCII && h.output == ["hello"] && h.state.englishInput.isEmpty, "Shift \(key) English-to-Chinese finalizes token once")
      h.type("nihao"); h.key(49, text: " ")
      try check(h.output == ["hello", "你好"] && h.raw.isEmpty, "Shift \(key) English-to-Chinese recovery uses real candidate")
      h.reset(ascii: false); h.tap(key)
      try check(h.modeASCII && h.output.isEmpty, "Shift \(key) empty Chinese-to-English tap")
      h.tap(key, at: 3)
      try check(!h.modeASCII && h.output.isEmpty, "Shift \(key) empty English-to-Chinese tap")
      h.reset(ascii: true); h.type("hello")
      h.flags(key, .shift, at: 4); h.flags(key, [], at: 4.8)
      try check(h.modeASCII && h.state.englishInput == "hello", "Shift \(key) long hold does not switch or lose input")
      h.flags(key, [], at: 5)
      try check(h.modeASCII, "Shift \(key) duplicate/orphan release cannot switch")
      h.flags(key, .shift, at: 5.1); h.flags(key, .shift, at: 5.11)
      try check(h.modeASCII && h.state.englishInput == "hello", "Shift \(key) duplicate press does not toggle before release")
      h.flags(key, [], at: 5.2)
      try check(!h.modeASCII && h.output == ["hello"], "Shift \(key) duplicate press still switches once on release")
      h.reset(ascii: true); h.type("hello")
      h.flags(key, .shift, at: 6); h.key(36, text: "\r", modifiers: .shift); h.flags(key, [], at: 6.1)
      try check(h.modeASCII && h.output == ["hello"], "Shift \(key) Return submits raw without treating release as a tap")
      h.reset(ascii: false)
      h.flags(key, .shift, at: 7); h.type("A", modifiers: .shift); h.flags(key, [], at: 7.1)
      try check(!h.modeASCII, "Shift \(key) Chinese uppercase input is not a mode tap")
      h.key(53, text: "\u{1b}"); h.type("nihao"); h.key(49, text: " ")
      try check(h.output.last == "你好", "Shift \(key) Chinese cancellation/recovery still works")
      h.reset(ascii: true); h.examples = false
      h.flags(key, .shift, at: 8); h.type("A", modifiers: .shift); h.flags(key, [], at: 8.1)
      try check(h.modeASCII && h.output == ["A"], "Shift \(key) Example Off uppercase direct input stays ASCII")
      h.reset(ascii: true); h.flags(key, .shift, at: 9)
      h.state.deactivate(); h.router.reset(); h.state.activate()
      h.flags(key, [], at: 9.1)
      try check(h.modeASCII && h.output.isEmpty, "Shift \(key) old-focus release cannot switch new focus")
    }

    h.reset(ascii: false); h.type("nihao"); h.tap(60)
    try check(h.output == ["你好"] && h.modeASCII && h.raw.isEmpty, "right tap preserves Chinese commit_text schema binding")
    h.type("world"); h.key(36, text: "\r")
    try check(h.output == ["你好", "world"], "right Chinese-to-English switch preserves both commits")

    h.reset(ascii: true); h.type("hello")
    let both = NSEvent.ModifierFlags(rawValue: ShiftModifierEvent.shiftMask | 0x6)
    let left = NSEvent.ModifierFlags(rawValue: ShiftModifierEvent.shiftMask | 0x2)
    h.flags(56, left, at: 10); h.flags(60, both, at: 10.01)
    h.flags(60, left, at: 10.02); h.flags(56, [], at: 10.1)
    try check(h.modeASCII && h.state.englishInput == "hello" && h.rightTapCount == 0, "overlapping physical Shifts are not independent taps")
    h.reset(ascii: true); h.type("hello")
    let right = NSEvent.ModifierFlags(rawValue: ShiftModifierEvent.shiftMask | 0x4)
    h.flags(60, right, at: 10); h.flags(56, both, at: 10.01)
    h.flags(56, right, at: 10.02); h.flags(60, [], at: 10.1)
    try check(h.modeASCII && h.state.englishInput == "hello" && h.rightTapCount == 0, "overlapping physical Shifts with reverse release order are not taps")
    h.reset(ascii: true); h.type("hello")
    h.flags(56, .shift, at: 10); h.flags(60, .shift, at: 10.01)
    h.flags(60, .shift, at: 10.02); h.flags(56, [], at: 10.1)
    try check(h.modeASCII && h.state.englishInput == "hello", "overlapping remote Shifts without device flags are not taps")
    h.reset(ascii: true); h.flags(56, .shift, at: 11)
    h.flags(58, [.shift, .option], at: 11.01)
    h.flags(58, .shift, at: 11.02); h.flags(56, [], at: 11.1)
    try check(h.modeASCII, "intervening Option press/release cancels armed Shift tap")

    h.reset(ascii: true); h.type("hello"); h.insertSucceeds = false; h.tap(56)
    try check(h.modeASCII && h.output.isEmpty, "failed host finalization does not also change mode")
    h.reset(ascii: true); h.type("hello")
    h.onInsert = { h.state.deactivate(); h.router.reset(); h.state.activate() }
    h.tap(60)
    try check(h.modeASCII && h.rightTapCount == 0 && h.output == ["hello"], "reentrant focus change stops right-tap replay after one commit")
    h.reset(ascii: true); h.type("hello")
    h.onInsert = { h.state.invalidate(); h.router.reset() }
    h.tap(56)
    try check(h.modeASCII && h.output == ["hello"], "reentrant cancellation prevents a later mode change")
    h.reset(ascii: true)
    h.flags(60, [.shift, .capsLock], at: 12); h.flags(60, .capsLock, at: 12.1)
    try check(h.modeASCII && h.output.isEmpty, "right-tap replay preserves Caps Lock modifier and inherited engine behavior")

    for cycle in 0..<10 {
      h.reset(ascii: false); h.type("nihao"); h.tap(56)
      h.type("hello"); h.tap(60, at: 2)
      h.type("zhongguo"); h.key(49, text: " ")
      try check(h.output == ["nihao", "hello", "中国"] && h.raw.isEmpty && h.state.englishInput.isEmpty,
                "repeated mixed composition cycle \(cycle + 1) has exact ordered output")
    }
  }
}

@_cdecl("EcholMERunShiftRegressions")
func runShiftRegressions(_ session: UInt) -> Int32 {
  do {
    ShiftRegressions.checks = []
    try ShiftRegressions.run(ShiftHarness(session: session))
    let report: [String: Any] = ["status": "PASS", "check_count": ShiftRegressions.checks.count,
      "checks": ShiftRegressions.checks,
      "scope": "production Shift router/key policy/state with real pinned librime and synthetic host; no IMK IPC/panel"]
    let data = try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys])
    fputs("ECHOLME_SHIFT_RESULT " + String(decoding: data, as: UTF8.self) + "\n", stderr)
    return Int32(ShiftRegressions.checks.count)
  } catch {
    fputs("Shift regression failed: \(error)\n", stderr)
    return 0
  }
}
