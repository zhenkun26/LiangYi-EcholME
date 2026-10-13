// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

private enum CheckError: Error { case failed(String) }

private struct Invocation {
  let processID: pid_t
  let includeText: Bool
  let onMainThread: Bool
}

private final class ProviderTrace {
  private let lock = NSLock()
  private var calls: [Invocation] = []
  private var active = 0
  private var peak = 0
  private var finished = 0
  private var waitFailures = 0

  func begin(_ processID: pid_t, includeText: Bool) {
    lock.lock()
    defer { lock.unlock() }
    calls.append(Invocation(processID: processID, includeText: includeText, onMainThread: Thread.isMainThread))
    active += 1
    peak = max(peak, active)
  }

  func end(waitSucceeded: Bool) {
    lock.lock()
    defer { lock.unlock() }
    active -= 1
    finished += 1
    if !waitSucceeded { waitFailures += 1 }
  }

  var snapshot: (calls: [Invocation], active: Int, peak: Int, finished: Int, waitFailures: Int) {
    lock.lock()
    defer { lock.unlock() }
    return (calls, active, peak, finished, waitFailures)
  }
}

private final class CallbackTrace {
  private let lock = NSLock()
  private var values: [pid_t: [ContextEvidence]] = [:]
  private var mainThreadOnly = true

  func record(_ processID: pid_t, evidence: ContextEvidence) {
    lock.lock()
    defer { lock.unlock() }
    values[processID, default: []].append(evidence)
    mainThreadOnly = mainThreadOnly && Thread.isMainThread
  }

  func results(_ processID: pid_t) -> [ContextEvidence] {
    lock.lock()
    defer { lock.unlock() }
    return values[processID] ?? []
  }

  var allOnMainThread: Bool {
    lock.lock()
    defer { lock.unlock() }
    return mainThreadOnly
  }
}

@main
struct ContextAsyncChecks {
  private static var checks: [String] = []
  private static let suiteDeadline = ProcessInfo.processInfo.systemUptime + 5

  private static func check(_ condition: @autoclosure () -> Bool, _ name: String) throws {
    guard condition() else { throw CheckError.failed(name) }
    checks.append(name)
  }

  // Run the real main-queue delivery path without starting AppKit or touching a
  // live AX element. Bounds are harness liveness limits, not latency claims.
  private static func pump(until condition: () -> Bool, timeout: TimeInterval = 1,
                           name: String) throws {
    let deadline = min(suiteDeadline, ProcessInfo.processInfo.systemUptime + timeout)
    while !condition() {
      guard ProcessInfo.processInfo.systemUptime < deadline else { throw CheckError.failed(name) }
      _ = RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.005))
    }
  }

  private static func settle(_ duration: TimeInterval = 0.05) throws {
    let deadline = ProcessInfo.processInfo.systemUptime + duration
    try pump(until: { ProcessInfo.processInfo.systemUptime >= deadline },
             timeout: duration + 0.2, name: "main queue did not settle within the harness deadline")
  }

  private static func ready(_ processID: pid_t) -> ContextEvidence {
    ContextEvidence(field: .text, language: .english, confidence: 1,
                    availability: .ready, reason: "synthetic_\(processID)")
  }

  @discardableResult
  private static func request(_ capture: ContextCapture, _ processID: pid_t,
                              includeText: Bool, results: CallbackTrace) -> ContextCaptureRequest {
    capture.request(processID: processID, includeText: includeText) {
      results.record(processID, evidence: $0)
    }
  }

  static func main() {
    do {
      try check(Thread.isMainThread, "all requests originate on the main thread")
      try latestPendingReplacesIntermediate()
      try watchdogDropsLateCompletion()
      try expiredPendingDoesNotRead()
      try cancellationSuppressesRunningAndPending()
      let report: [String: Any] = ["status": "PASS", "check_count": checks.count, "checks": checks]
      let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
      print(String(decoding: data, as: UTF8.self))
    } catch {
      fputs("Round 3 asynchronous context checks failed: \(error)\n", stderr)
      exit(1)
    }
  }

  private static func latestPendingReplacesIntermediate() throws {
    let release = DispatchSemaphore(value: 0)
    let provider = ProviderTrace()
    let callbacks = CallbackTrace()
    // Supplying read explicitly ensures the production default AX reader is
    // never instantiated by this executable. These PIDs are fixture labels.
    let capture = ContextCapture(read: { processID, includeText in
      provider.begin(processID, includeText: includeText)
      let released = processID != 101 || release.wait(timeout: .now() + 1) == .success
      defer { provider.end(waitSucceeded: released) }
      return ready(processID)
    })
    request(capture, 101, includeText: true, results: callbacks)
    try pump(until: { provider.snapshot.active == 1 }, name: "first synthetic provider did not start")
    request(capture, 102, includeText: true, results: callbacks)
    request(capture, 103, includeText: false, results: callbacks)
    release.signal()
    try pump(until: { (101...103).allSatisfy { callbacks.results(pid_t($0)).count == 1 } },
             name: "burst callbacks did not finish")
    try settle()
    let trace = provider.snapshot
    try check(trace.calls.map(\.processID) == [101, 103],
              "blocked first request keeps only the newest pending provider invocation")
    try check(trace.calls.map(\.includeText) == [true, false],
              "latest pending request preserves its own text access policy")
    try check(trace.peak == 1 && trace.active == 0 && trace.finished == 2,
              "provider invocations run serially with no overlap")
    try check(trace.calls.allSatisfy { !$0.onMainThread },
              "provider work stays off the main thread")
    try check(callbacks.results(101).first?.reason == "synthetic_101",
              "first released request delivers its own evidence")
    try check(callbacks.results(103).first?.reason == "synthetic_103",
              "newest request delivers evidence rather than an intermediate result")
    try check(callbacks.results(102).first?.availability == .timedOut,
              "superseded pending request terminates through its watchdog")
    try check((101...103).allSatisfy { callbacks.results(pid_t($0)).count == 1 },
              "each burst request calls back once after all watchdogs become eligible")
    try check(callbacks.allOnMainThread, "burst callbacks are delivered on the main thread")
    try check(trace.waitFailures == 0, "burst provider was explicitly released within its bounded wait")
  }

  private static func watchdogDropsLateCompletion() throws {
    let release = DispatchSemaphore(value: 0)
    let provider = ProviderTrace()
    let callbacks = CallbackTrace()
    let capture = ContextCapture(read: { processID, includeText in
      provider.begin(processID, includeText: includeText)
      let released = release.wait(timeout: .now() + 1) == .success
      defer { provider.end(waitSucceeded: released) }
      return ContextDetector.detect(text: "", field: .secure)
    })
    request(capture, 201, includeText: false, results: callbacks)
    try pump(until: { provider.snapshot.active == 1 }, name: "watchdog fixture provider did not start")
    try pump(until: { callbacks.results(201).count == 1 }, name: "watchdog did not complete blocked request")
    try check(callbacks.results(201).first?.availability == .timedOut,
              "watchdog releases the decision while the provider is still blocked")
    try check(provider.snapshot.active == 1 && provider.snapshot.finished == 0,
              "watchdog does not wait for synchronous provider completion")
    release.signal()
    try pump(until: { provider.snapshot.finished == 1 }, name: "late provider did not finish after release")
    try settle()
    try check(callbacks.results(201).count == 1,
              "late normal completion cannot deliver a second callback after timeout")
    try check(callbacks.results(201).first?.field == .unknown,
              "late secure evidence does not replace the already delivered timeout")
    try check(callbacks.allOnMainThread, "watchdog callback is delivered on the main thread")
    try check(provider.snapshot.waitFailures == 0,
              "watchdog provider was explicitly released within its bounded wait")
  }

  private static func expiredPendingDoesNotRead() throws {
    let release = DispatchSemaphore(value: 0)
    let provider = ProviderTrace()
    let callbacks = CallbackTrace()
    let capture = ContextCapture(read: { processID, includeText in
      provider.begin(processID, includeText: includeText)
      let released = processID != 301 || release.wait(timeout: .now() + 1) == .success
      defer { provider.end(waitSucceeded: released) }
      return ready(processID)
    })
    request(capture, 301, includeText: true, results: callbacks)
    try pump(until: { provider.snapshot.active == 1 }, name: "expired pending fixture did not start")
    request(capture, 302, includeText: true, results: callbacks)
    try pump(until: { callbacks.results(301).count == 1 && callbacks.results(302).count == 1 },
             name: "pending request watchdog did not finish before release")
    try check(callbacks.results(301).first?.availability == .timedOut &&
              callbacks.results(302).first?.availability == .timedOut,
              "running and pending requests can expire while the worker stays occupied")
    release.signal()
    try pump(until: { provider.snapshot.finished == 1 }, name: "expired pending worker did not resume")
    try settle()
    try check(provider.snapshot.calls.map(\.processID) == [301],
              "expired pending ticket skips provider access when the worker becomes available")
    try check(callbacks.results(301).count == 1 && callbacks.results(302).count == 1,
              "resumed worker cannot duplicate running or pending timeout callbacks")

    request(capture, 303, includeText: false, results: callbacks)
    try pump(until: { callbacks.results(303).count == 1 }, name: "fresh request after timeout did not finish")
    // Drain the final request's watchdog too, proving successful completion is
    // not followed by a second timeout callback.
    try settle(0.25)
    try check(provider.snapshot.calls.map(\.processID) == [301, 303],
              "capture queue recovers and reads a fresh request after expired work")
    try check(callbacks.results(303).first?.reason == "synthetic_303" && callbacks.results(303).count == 1,
              "fresh successful request keeps its result after its watchdog deadline")
    try check(callbacks.allOnMainThread, "expired and recovered callbacks remain on the main thread")
    try check(provider.snapshot.peak == 1 && provider.snapshot.active == 0,
              "recovery preserves serial worker ownership")
    try check(provider.snapshot.waitFailures == 0,
              "expired pending fixture was explicitly released within its bounded wait")
  }

  private static func cancellationSuppressesRunningAndPending() throws {
    let release = DispatchSemaphore(value: 0)
    let cancellationFinished = DispatchSemaphore(value: 0)
    let provider = ProviderTrace()
    let callbacks = CallbackTrace()
    let capture = ContextCapture(read: { processID, includeText in
      provider.begin(processID, includeText: includeText)
      let released = processID != 401 || release.wait(timeout: .now() + 1) == .success
      defer { provider.end(waitSucceeded: released) }
      return ready(processID)
    })
    let running = request(capture, 401, includeText: true, results: callbacks)
    try pump(until: { provider.snapshot.active == 1 }, name: "cancellation fixture provider did not start")
    let pending = request(capture, 402, includeText: true, results: callbacks)
    // Cancellation may arrive off the controller thread; repeated calls must
    // remain harmless while the main queue owns eventual completion delivery.
    DispatchQueue.global(qos: .userInitiated).async {
      running.cancel()
      pending.cancel()
      running.cancel()
      pending.cancel()
      cancellationFinished.signal()
    }
    try pump(until: { cancellationFinished.wait(timeout: .now()) == .success },
             name: "background request cancellation did not finish")
    try settle(0.25)
    try check(callbacks.results(401).isEmpty,
              "cancelled running request suppresses its watchdog callback")
    try check(callbacks.results(402).isEmpty,
              "cancelled pending request suppresses its watchdog callback")
    try check(provider.snapshot.active == 1 && provider.snapshot.finished == 0,
              "cancellation does not pretend to interrupt an in flight synchronous read")
    release.signal()
    try pump(until: { provider.snapshot.finished == 1 }, name: "cancelled running provider did not resume")
    try settle()
    try check(provider.snapshot.calls.map(\.processID) == [401],
              "cancelled pending request never reaches the provider after worker release")
    try check(callbacks.results(401).isEmpty && callbacks.results(402).isEmpty,
              "late completion cannot revive cancelled running or pending callbacks")

    request(capture, 403, includeText: false, results: callbacks)
    try pump(until: { callbacks.results(403).count == 1 }, name: "fresh request after cancellation did not finish")
    try settle(0.25)
    try check(provider.snapshot.calls.map(\.processID) == [401, 403],
              "fresh request recovers after cancellation without reading cancelled pending work")
    try check(callbacks.results(403).first?.reason == "synthetic_403" && callbacks.results(403).count == 1,
              "successful post cancellation request delivers exactly once")
    try check(callbacks.allOnMainThread && provider.snapshot.peak == 1 && provider.snapshot.active == 0,
              "cross thread cancellation preserves main callbacks and serial provider ownership")
    try check(provider.snapshot.waitFailures == 0,
              "cancelled provider was explicitly released within its bounded wait")
  }
}
