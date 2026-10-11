// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.
// Read-only Round 0 diagnostic. Never reads document text or prompts for AX access.
import AppKit
import ApplicationServices
import Carbon
import Foundation

func sourceString(_ source: TISInputSource, _ key: CFString) -> String? {
  guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
  return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
}

func sourceBool(_ source: TISInputSource, _ key: CFString) -> Bool? {
  guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
  return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue())
}

func axValue(_ element: AXUIElement, _ name: CFString) -> (AXError, CFTypeRef?) {
  var value: CFTypeRef?
  let error = AXUIElementCopyAttributeValue(element, name, &value)
  return (error, value)
}

func axReport(bundleID: String?) -> [String: Any] {
  let trusted = AXIsProcessTrusted()
  var result: [String: Any] = ["trusted": trusted,
    "permission_prompt_requested": false, "document_text_read": false,
    "scope": "external AX process; not proof of IMK client support or IME AX permission"]
  guard trusted else {
    result["status"] = "BLOCKED_PERMISSION"
    return result
  }
  let application: NSRunningApplication?
  if let bundleID {
    application = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
  } else {
    application = NSWorkspace.shared.frontmostApplication
  }
  guard let application else {
    result["status"] = "BLOCKED_APP_NOT_RUNNING"
    return result
  }
  result["application_bundle_id"] = application.bundleIdentifier ?? "unknown"
  let app = AXUIElementCreateApplication(application.processIdentifier)
  let appTimeout = AXUIElementSetMessagingTimeout(app, 0.2)
  result["timeout_status"] = appTimeout.rawValue
  result["timeout_scope"] = "per AX message; run under an external process deadline for a total bound"
  guard appTimeout == .success else {
    result["status"] = "BLOCKED_TIMEOUT_CONFIGURATION"
    return result
  }
  let start = ContinuousClock.now
  let (focusStatus, focusedValue) = axValue(app, kAXFocusedUIElementAttribute as CFString)
  result["focused_element_status"] = focusStatus.rawValue
  guard focusStatus == .success, let focusedValue,
        CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
    result["status"] = "BLOCKED_FOCUSED_ELEMENT_UNAVAILABLE"
    return result
  }
  let focused = unsafeBitCast(focusedValue, to: AXUIElement.self)
  let elementTimeout = AXUIElementSetMessagingTimeout(focused, 0.2)
  result["element_timeout_status"] = elementTimeout.rawValue
  guard elementTimeout == .success else {
    result["status"] = "BLOCKED_TIMEOUT_CONFIGURATION"
    return result
  }
  // Role metadata is safe to inspect; never fetch AXValue, AXSelectedText, or titles.
  for (key, attribute) in [("role", kAXRoleAttribute), ("subrole", kAXSubroleAttribute)] {
    let (status, value) = axValue(focused, attribute as CFString)
    result[key + "_status"] = status.rawValue
    if status == .success, let value, CFGetTypeID(value) == CFStringGetTypeID() {
      result[key] = value as? String
    }
  }
  let secure = (result["subrole"] as? String) == "AXSecureTextField"
  result["secure_field_assessment"] = result["subrole"] == nil
    ? "unknown" : (secure ? "secure" : "not_reported_secure")
  guard !secure else {
    result["status"] = "SKIPPED_SECURE_FIELD"
    return result
  }
  var attributeNames: CFArray?
  let attributesStatus = AXUIElementCopyAttributeNames(focused, &attributeNames)
  let names = attributeNames as? [String] ?? []
  var parameterNames: CFArray?
  let parameterStatus = AXUIElementCopyParameterizedAttributeNames(focused, &parameterNames)
  let parameters = parameterNames as? [String] ?? []
  result["attribute_names_status"] = attributesStatus.rawValue
  result["parameter_names_status"] = parameterStatus.rawValue
  if attributesStatus == .success {
    result["advertises_text_value"] = names.contains(kAXValueAttribute)
    result["advertises_selected_text"] = names.contains(kAXSelectedTextAttribute)
    result["advertises_selected_range"] = names.contains(kAXSelectedTextRangeAttribute)
    result["advertises_language"] = names.contains("AXLanguage")
  }
  if parameterStatus == .success {
    result["advertises_bounds_for_range"] = parameters.contains(kAXBoundsForRangeParameterizedAttribute)
  }
  // Read only the insertion range, never its text; output no offsets or coordinates.
  if names.contains(kAXSelectedTextRangeAttribute),
     parameters.contains(kAXBoundsForRangeParameterizedAttribute) {
    let (rangeStatus, rangeValue) = axValue(focused, kAXSelectedTextRangeAttribute as CFString)
    result["selection_range_status"] = rangeStatus.rawValue
    if rangeStatus == .success, let rangeValue,
       CFGetTypeID(rangeValue) == AXValueGetTypeID() {
      let axRange = unsafeBitCast(rangeValue, to: AXValue.self)
      var range = CFRange()
      if AXValueGetValue(axRange, .cfRange, &range), range.length == 0 {
        // A nonempty selection does not reveal which end is the active caret.
        if let insertionRange = AXValueCreate(.cfRange, &range) {
          var boundsValue: CFTypeRef?
          let status = AXUIElementCopyParameterizedAttributeValue(focused,
            kAXBoundsForRangeParameterizedAttribute as CFString, insertionRange, &boundsValue)
          result["caret_bounds_status"] = status.rawValue
          if status == .success, let boundsValue, CFGetTypeID(boundsValue) == AXValueGetTypeID() {
            var bounds = CGRect.zero
            let boundsAX = unsafeBitCast(boundsValue, to: AXValue.self)
            result["caret_bounds_finite_nonzero_height"] = AXValueGetValue(boundsAX, .cgRect, &bounds)
              && bounds.origin.x.isFinite && bounds.origin.y.isFinite
              && bounds.width.isFinite && bounds.height.isFinite && bounds.height > 0
          }
        }
      }
    }
  }
  let duration = start.duration(to: .now).components
  result["elapsed_ms"] = Double(duration.seconds) * 1_000 + Double(duration.attoseconds) / 1e15
  result["status"] = attributesStatus == .success && parameterStatus == .success
    ? "METADATA_PROBED" : "PARTIAL_METADATA_PROBE"
  return result
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count <= 1 else {
  fputs("Usage: capability-probe [application-bundle-id]\n", stderr)
  exit(64)
}
let listResult = TISCreateInputSourceList(nil, true)
let allSources = listResult?.takeRetainedValue() as? [TISInputSource] ?? []
let sources: [[String: Any]] = allSources.compactMap { source in
  guard let identifier = sourceString(source, kTISPropertyInputSourceID),
        identifier.hasPrefix("io.github.zhenkun26.inputmethod.EcholME")
          || identifier.hasPrefix("im.rime.inputmethod.Squirrel") else { return nil }
  var row: [String: Any] = ["id": identifier]
  row["enabled"] = sourceBool(source, kTISPropertyInputSourceIsEnabled)
  row["selectable"] = sourceBool(source, kTISPropertyInputSourceIsSelectCapable)
  row["selected"] = sourceBool(source, kTISPropertyInputSourceIsSelected)
  return row
}
let probeStarted = ContinuousClock.now
var context = axReport(bundleID: arguments.first)
let totalDuration = probeStarted.duration(to: .now).components
context["total_elapsed_ms"] = Double(totalDuration.seconds) * 1_000 + Double(totalDuration.attoseconds) / 1e15
var report: [String: Any] = [
  "schema_version": 1,
  "timestamp": ISO8601DateFormatter().string(from: Date()),
  "os": ProcessInfo.processInfo.operatingSystemVersionString,
  "matching_input_sources": sources,
  "tis_list_available": listResult != nil,
  "ax": context,
  "mutations_performed": false
]
if let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
  report["current_input_source"] = sourceString(current, kTISPropertyInputSourceID)
}
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data("\n".utf8))
