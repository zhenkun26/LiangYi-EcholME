//
//  InputSource.swift
//  Squirrel
//
//  Created by Leo Liu on 5/10/24.
//  Modified for EcholME on 2026-10-11: isolated source IDs and truthful TIS results.
//

import Foundation
import InputMethodKit

final class SquirrelInstaller {
  enum InputMode: String, CaseIterable {
    static let primary = Self.hans
    case hans = "io.github.zhenkun26.inputmethod.EcholME.Hans"
    case hant = "io.github.zhenkun26.inputmethod.EcholME.Hant"
  }
  // TIS state can change after registration or a System Settings action. Never
  // retain a lazy snapshot across CLI operations.
  private func inputSources() -> [String: TISInputSource] {
    var inputSources = [String: TISInputSource]()
    guard let sourceList = TISCreateInputSourceList(nil, true)?.takeRetainedValue() as? [TISInputSource] else {
      return inputSources
    }
    for inputSource in sourceList {
      guard let sourceID = Self.getString(for: inputSource, key: kTISPropertyInputSourceID) else { continue }
      inputSources[sourceID] = inputSource
    }
    return inputSources
  }

  func enabledModes() -> [InputMode] {
    var enabledModes = Set<InputMode>()
    for (mode, inputSource) in getInputSource(modes: InputMode.allCases) {
      if let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled), enabled {
        enabledModes.insert(mode)
      }
      if enabledModes.count == InputMode.allCases.count {
        break
      }
    }
    return Array(enabledModes)
  }

  func register() -> Bool {
    guard Bundle.main.bundleIdentifier == SquirrelApp.bundleIdentifier,
          SquirrelApp.appDir.pathExtension == "app" else {
      SquirrelApp.reportCommandError("Refusing to register a bundle without EcholME's application identity.")
      return false
    }
    let status = TISRegisterInputSource(SquirrelApp.appDir as CFURL)
    guard report(status, action: "Register", sourceID: SquirrelApp.bundleIdentifier) else { return false }
    let registered = getInputSource(modes: InputMode.allCases).keys.map(\.rawValue).sorted()
    print("Visible EcholME modes after registration: \(registered)")
    // OSStatus confirms the request result. Registration visibility, enablement,
    // selection, and real typing are separate checks, never implied by this line.
    return true
  }

  func enable(modes: [InputMode] = []) -> Bool {
    let enabledInputModes = enabledModes()
    if !enabledInputModes.isEmpty && modes.isEmpty {
      print("User already enabled EcholME method(s): \(enabledInputModes.map { $0.rawValue }.sorted())")
      // Preserve manually enabled input modes.
      return true
    }
    let modesToEnable = modes.isEmpty ? [.primary] : modes
    var succeeded = true
    for mode in modesToEnable {
      guard let inputSource = getInputSource(modes: [mode])[mode],
            let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled) else {
        SquirrelApp.reportCommandError("Input source is unavailable: \(mode.rawValue)")
        succeeded = false
        continue
      }
      if !enabled {
        let status = TISEnableInputSource(inputSource)
        if !report(status, action: "Enable", sourceID: mode.rawValue) { succeeded = false }
      }
    }
    return succeeded
  }

  func select(mode: InputMode? = nil) -> Bool {
    let modeToSelect = mode ?? .primary
    guard let inputSource = getInputSource(modes: [modeToSelect])[modeToSelect],
          getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled) == true,
          getBool(for: inputSource, key: kTISPropertyInputSourceIsSelectCapable) == true else {
      SquirrelApp.reportCommandError("Input source must be explicitly enabled and selectable first: \(modeToSelect.rawValue)")
      return false
    }
    if getBool(for: inputSource, key: kTISPropertyInputSourceIsSelected) == true {
      print("Input source is already selected: \(modeToSelect.rawValue)")
      return true
    }
    return report(TISSelectInputSource(inputSource), action: "Select", sourceID: modeToSelect.rawValue)
  }

  static func currentInputSourceID() -> String? {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
    return getString(for: source, key: kTISPropertyInputSourceID)
  }

  func disable(modes: [InputMode] = []) -> Bool {
    let modesToDisable = modes.isEmpty ? InputMode.allCases : modes
    var succeeded = true
    for mode in modesToDisable {
      guard let inputSource = getInputSource(modes: [mode])[mode],
            let enabled = getBool(for: inputSource, key: kTISPropertyInputSourceIsEnabled) else {
        SquirrelApp.reportCommandError("Input source is unavailable: \(mode.rawValue)")
        succeeded = false
        continue
      }
      if enabled {
        let status = TISDisableInputSource(inputSource)
        if !report(status, action: "Disable", sourceID: mode.rawValue) { succeeded = false }
      }
    }
    return succeeded
  }

  private func getInputSource(modes: [InputMode]) -> [InputMode: TISInputSource] {
    var matchingSources = [InputMode: TISInputSource]()
    let sources = inputSources()
    for mode in modes {
      if let inputSource = sources[mode.rawValue] {
        matchingSources[mode] = inputSource
      }
    }
    return matchingSources
  }

  private func getBool(for inputSource: TISInputSource, key: CFString!) -> Bool? {
    guard let value = TISGetInputSourceProperty(inputSource, key) else { return nil }
    return Unmanaged<CFTypeRef>.fromOpaque(value).takeUnretainedValue() as? Bool
  }

  private static func getString(for inputSource: TISInputSource, key: CFString) -> String? {
    guard let value = TISGetInputSourceProperty(inputSource, key) else { return nil }
    return Unmanaged<CFTypeRef>.fromOpaque(value).takeUnretainedValue() as? String
  }

  private func report(_ status: OSStatus, action: String, sourceID: String) -> Bool {
    let message = "\(action) request returned OSStatus \(status) for \(sourceID)"
    if status == noErr {
      print(message)
      return true
    }
    SquirrelApp.reportCommandError(message)
    return false
  }
}
