// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import AppKit
import ApplicationServices

// This store is owned by the IMK/UI thread. Only small policy values are
// persisted: there is no document text, selected text, or translation history.
final class ContextPreferences {
  static let shared = ContextPreferences()
  static let didChange = Notification.Name("EcholMEContextPreferencesChanged")
  static let maximumStoredBytes = 64 * 1024
  static let maximumAppEntries = 128
  static let defaultStorageKey = "EcholME.ContextPreferences.v1"

  private(set) var settings: ContextSettings
  private let defaults: UserDefaults
  private let storageKey: String

  init(defaults: UserDefaults = .standard, storageKey: String = ContextPreferences.defaultStorageKey) {
    precondition(Thread.isMainThread)
    self.defaults = defaults
    self.storageKey = storageKey
    if let data = defaults.data(forKey: storageKey),
       data.count <= Self.maximumStoredBytes,
       let decoded = try? JSONDecoder().decode(ContextSettings.self, from: data),
       Self.isValid(decoded) {
      settings = decoded
    } else {
      // Invalid or future-format data is left intact until an explicit save.
      settings = ContextSettings()
    }
  }

  @discardableResult
  func update(_ transform: (inout ContextSettings) -> Void) -> Bool {
    precondition(Thread.isMainThread)
    var proposed = settings
    transform(&proposed)
    return save(proposed, notify: true)
  }

  func recordManual(_ direction: InputDirection, bundleID: String) {
    precondition(Thread.isMainThread)
    guard settings.learningEnabled, Self.isValidBundleID(bundleID) else { return }
    var proposed = settings
    let existing = proposed.learned[bundleID]
    let count = existing?.direction == direction ? min(3, (existing?.count ?? 0) + 1) : 1
    proposed.learned[bundleID] = LearnedPreference(direction: direction, count: count)
    // The active controller already owns this choice. Posting synchronously
    // here would reenter mode resolution in the middle of a manual transition.
    _ = save(proposed, notify: false)
  }

  static func isValidBundleID(_ value: String) -> Bool {
    guard !value.isEmpty, value.utf8.count <= 255 else { return false }
    let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
    return value.unicodeScalars.allSatisfy { allowed.contains($0) }
      && value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy { !$0.isEmpty }
  }

  static func isValid(_ settings: ContextSettings) -> Bool {
    let appIDs = Set(settings.forceRules.keys).union(settings.learned.keys)
    return appIDs.count <= maximumAppEntries
      && appIDs.allSatisfy(isValidBundleID)
      && settings.learned.values.allSatisfy { (1...3).contains($0.count) }
  }

  private func save(_ proposed: ContextSettings, notify: Bool) -> Bool {
    guard Self.isValid(proposed),
          let data = try? JSONEncoder().encode(proposed),
          data.count <= Self.maximumStoredBytes else { return false }
    guard proposed != settings else { return true }
    defaults.set(data, forKey: storageKey)
    settings = proposed
    if notify {
      NotificationCenter.default.post(name: Self.didChange, object: self)
    }
    return true
  }
}

final class ContextSettingsWindow: NSWindowController {
  static let shared = ContextSettingsWindow()

  private let modePopup = NSPopUpButton(frame: .zero, pullsDown: false)
  private let fallbackPopup = NSPopUpButton(frame: .zero, pullsDown: false)
  private let contextToggle = NSButton(checkboxWithTitle: "Use nearby text and field signals in Auto mode", target: nil, action: nil)
  private let learningToggle = NSButton(checkboxWithTitle: "Learn my manual language choices per app (optional)", target: nil, action: nil)
  private let bundleField = NSTextField()
  private let ruleDirectionPopup = NSPopUpButton(frame: .zero, pullsDown: false)
  private let ruleList = NSTextView()
  private let trustLabel = NSTextField(wrappingLabelWithString: "")
  private let resultLabel = NSTextField(wrappingLabelWithString: "")
  private static let modes: [PrimaryInputMode] = [.auto, .chinese, .english, .off]
  private static let directions: [InputDirection] = [.chinese, .english]

  private init() {
    precondition(Thread.isMainThread)
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 650, height: 710),
                          styleMask: [.titled, .closable, .miniaturizable],
                          backing: .buffered, defer: false)
    window.title = "EcholME — Input Context"
    window.isReleasedWhenClosed = false
    super.init(window: window)
    buildContent(in: window)
    window.center()
  }

  required init?(coder: NSCoder) { nil }

  func show() {
    precondition(Thread.isMainThread)
    prepareForDisplay()
    showWindow(nil)
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  static func showAbout() {
    precondition(Thread.isMainThread)
    let alert = NSAlert()
    let version = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
      ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "development"
    alert.messageText = "两仪 / EcholME \(version)"
    alert.informativeText = "A Squirrel-derived input method powered by librime.\n\nFrontend: GNU GPL version 3. Existing upstream copyright and license notices are retained.\n\nDictionary: CC-CEDICT, published by MDBG, under CC BY-SA 4.0. The derived dictionary retains its own data license.\n\nBundled notices include dependency and dictionary attribution. Local build verification does not establish readiness for public distribution."
    alert.addButton(withTitle: "Close")
    alert.addButton(withTitle: "Open Bundled Licenses")
    if alert.runModal() == .alertSecondButtonReturn, let resources = Bundle.main.resourceURL {
      let paths = ["LICENSE.txt", "THIRD_PARTY_NOTICES.md", "NOTICE.txt", "Licenses"]
        .map { resources.appendingPathComponent($0) }
        .filter { FileManager.default.fileExists(atPath: $0.path) }
      if !paths.isEmpty { NSWorkspace.shared.activateFileViewerSelecting(paths) }
    }
  }

  private func buildContent(in window: NSWindow) {
    guard let content = window.contentView else { return }
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 10
    stack.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
      stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
      stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 22),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -22)
    ])

    let heading = NSTextField(labelWithString: "Primary input language")
    heading.font = .boldSystemFont(ofSize: 15)
    stack.addArrangedSubview(heading)
    modePopup.addItems(withTitles: ["Auto", "Chinese → English", "English → Chinese", "Off — literal input passthrough"])
    fallbackPopup.addItems(withTitles: ["Chinese", "English"])
    let grid = NSGridView(views: [
      [NSTextField(labelWithString: "Mode"), modePopup],
      [NSTextField(labelWithString: "Auto fallback"), fallbackPopup]
    ])
    grid.column(at: 0).xPlacement = .trailing
    grid.column(at: 0).width = 90
    grid.column(at: 1).xPlacement = .leading
    grid.column(at: 1).width = 260
    grid.columnSpacing = 12
    stack.addArrangedSubview(grid)
    grid.widthAnchor.constraint(equalToConstant: 362).isActive = true
    stack.addArrangedSubview(contextToggle)
    stack.addArrangedSubview(learningToggle)
    let privacy = NSTextField(wrappingLabelWithString: "Nearby-text analysis uses at most 128 UTF-16 units before the caret, locally and transiently. It is not saved or sent to a server. Accessibility access enables this bounded context check; ordinary input works without permission, and this panel never requests permission.")
    privacy.font = .systemFont(ofSize: 12)
    privacy.textColor = .secondaryLabelColor
    privacy.preferredMaxLayoutWidth = 606
    stack.addArrangedSubview(privacy)
    trustLabel.font = .systemFont(ofSize: 12)
    stack.addArrangedSubview(trustLabel)
    let applyRow = NSStackView(views: [
      actionButton("Apply Settings", #selector(applySettings)),
      actionButton("Clear Learned Preferences", #selector(clearLearned))
    ])
    applyRow.spacing = 12
    stack.addArrangedSubview(applyRow)

    let ruleHeading = NSTextField(labelWithString: "Force a primary language for an app")
    ruleHeading.font = .boldSystemFont(ofSize: 14)
    stack.addArrangedSubview(ruleHeading)
    let ruleNote = NSTextField(wrappingLabelWithString: "Rules apply in Auto mode. A current manual choice has priority; sensitive-field protections always take priority. Up to 128 app IDs are stored across rules and learned preferences.")
    ruleNote.font = .systemFont(ofSize: 12)
    ruleNote.textColor = .secondaryLabelColor
    ruleNote.preferredMaxLayoutWidth = 606
    stack.addArrangedSubview(ruleNote)
    bundleField.placeholderString = "App bundle ID, e.g. com.apple.dt.Xcode"
    bundleField.setAccessibilityLabel("App bundle ID")
    ruleDirectionPopup.addItems(withTitles: ["Chinese", "English"])
    let ruleEntry = NSStackView(views: [bundleField, ruleDirectionPopup])
    ruleEntry.spacing = 10
    ruleEntry.distribution = .fill
    stack.addArrangedSubview(ruleEntry)
    ruleEntry.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    bundleField.widthAnchor.constraint(greaterThanOrEqualToConstant: 380).isActive = true
    let ruleActions = NSStackView(views: [
      actionButton("Save Rule", #selector(saveRule)),
      actionButton("Remove Rule", #selector(removeRule))
    ])
    ruleActions.spacing = 12
    stack.addArrangedSubview(ruleActions)

    ruleList.isEditable = false
    ruleList.isSelectable = true
    ruleList.frame = NSRect(x: 0, y: 0, width: 606, height: 105)
    ruleList.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    ruleList.textContainerInset = NSSize(width: 8, height: 8)
    ruleList.setAccessibilityLabel("Saved app language rules")
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.borderType = .bezelBorder
    scroll.documentView = ruleList
    ruleList.isVerticallyResizable = true
    ruleList.isHorizontallyResizable = false
    ruleList.autoresizingMask = [.width]
    ruleList.textContainer?.widthTracksTextView = true
    stack.addArrangedSubview(scroll)
    scroll.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    scroll.heightAnchor.constraint(equalToConstant: 105).isActive = true
    resultLabel.font = .systemFont(ofSize: 12)
    resultLabel.preferredMaxLayoutWidth = 606
    stack.addArrangedSubview(resultLabel)
  }

  private func actionButton(_ title: String, _ action: Selector) -> NSButton {
    NSButton(title: title, target: self, action: action)
  }

  // The preview tool supplies synthetic settings without touching preferences
  // or activating a window. Normal presentation reads the current store.
  func prepareForDisplay(settings: ContextSettings = ContextPreferences.shared.settings, status: String = "") {
    precondition(Thread.isMainThread)
    modePopup.selectItem(at: Self.modes.firstIndex(of: settings.mode) ?? 0)
    fallbackPopup.selectItem(at: Self.directions.firstIndex(of: settings.globalDirection) ?? 0)
    contextToggle.state = settings.contextEnabled ? .on : .off
    learningToggle.state = settings.learningEnabled ? .on : .off
    trustLabel.stringValue = AXIsProcessTrusted()
      ? "Accessibility: available. Bounded field and nearby-text checks are available."
      : "Accessibility: unavailable. Manual language selection and fallback rules remain available."
    reloadRules(settings: settings)
    resultLabel.stringValue = status
  }

  private func reloadRules(settings: ContextSettings = ContextPreferences.shared.settings) {
    let rules = settings.forceRules
    ruleList.string = rules.isEmpty ? "No force rules saved."
      : rules.keys.sorted().map { "\($0)  →  \(rules[$0] == .english ? "English" : "Chinese")" }.joined(separator: "\n")
  }

  @objc private func applySettings() {
    guard Self.modes.indices.contains(modePopup.indexOfSelectedItem),
          Self.directions.indices.contains(fallbackPopup.indexOfSelectedItem) else { return }
    let saved = ContextPreferences.shared.update { settings in
      settings.mode = Self.modes[modePopup.indexOfSelectedItem]
      settings.globalDirection = Self.directions[fallbackPopup.indexOfSelectedItem]
      settings.contextEnabled = contextToggle.state == .on
      settings.learningEnabled = learningToggle.state == .on
    }
    showResult(saved ? "Settings applied. Explicit language changes finish pending text; automatic decisions wait for an empty composition." : "Settings could not be saved; existing preferences were preserved.", success: saved)
  }

  @objc private func clearLearned() {
    let saved = ContextPreferences.shared.update { $0.learned = [:] }
    showResult(saved ? "Learned app preferences cleared; explicit rules were preserved." : "Could not clear learned preferences.", success: saved)
  }

  @objc private func saveRule() {
    guard let id = validatedRuleID(), Self.directions.indices.contains(ruleDirectionPopup.indexOfSelectedItem) else { return }
    let direction = Self.directions[ruleDirectionPopup.indexOfSelectedItem]
    let saved = ContextPreferences.shared.update { $0.forceRules[id] = direction }
    reloadRules()
    showResult(saved ? "Rule saved. It applies in Auto mode after the current composition." : "Rule not saved: the 128-app or storage-size limit was reached. Existing preferences were preserved.", success: saved)
  }

  @objc private func removeRule() {
    guard let id = validatedRuleID() else { return }
    guard ContextPreferences.shared.settings.forceRules[id] != nil else {
      showResult("No saved force rule matches that app ID.", success: false)
      return
    }
    let saved = ContextPreferences.shared.update { $0.forceRules[id] = nil }
    reloadRules()
    showResult(saved ? "Force rule removed. Learned preferences and other rules were preserved." : "Rule could not be removed.", success: saved)
  }

  private func validatedRuleID() -> String? {
    let id = bundleField.stringValue
    guard ContextPreferences.isValidBundleID(id) else {
      showResult("Use an app bundle ID of 1–255 ASCII letters, digits, dots, hyphens or underscores, without spaces or empty dot segments.", success: false)
      return nil
    }
    return id
  }

  private func showResult(_ message: String, success: Bool) {
    resultLabel.textColor = success ? .secondaryLabelColor : .systemRed
    resultLabel.stringValue = message
  }
}
