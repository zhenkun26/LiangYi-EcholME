//
//  Main.swift
//  Squirrel
//
//  Created by Leo Liu on 5/10/24.
//  Modified for EcholME on 2026-10-11: independent identity and explicit CLI results.
//

import Foundation
import InputMethodKit
import Darwin

// Keep notifications separate from Squirrel even when both input methods run.
enum EcholMENotification {
  static let reload = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.Reload")
  static let sync = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.Sync")
  static let toggleASCII = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.ToggleASCII")
  static let getASCII = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.GetASCII")
  static let asciiResponse = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.ASCIIResponse")
  static let setASCII = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.SetASCII")
  static let reportASCII = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.ReportASCII")
  static let engineWillReset = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.EngineWillReset")
  static let lexiconReady = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.LexiconReady")
  static let lexiconFailed = Notification.Name("io.github.zhenkun26.inputmethod.EcholME.LexiconFailed")
}

@main
struct SquirrelApp {
  static let bundleIdentifier = "io.github.zhenkun26.inputmethod.EcholME"
  private static let homeDir = if let pwuid = getpwuid(getuid()) {
    URL(fileURLWithFileSystemRepresentation: pwuid.pointee.pw_dir, isDirectory: true, relativeTo: nil)
  } else {
    FileManager.default.homeDirectoryForCurrentUser
  }
  static let userDir = homeDir.appending(components: "Library", "Application Support", "LiangYi", "Rime")
  static let appDir = Bundle.main.bundleURL
  static let logDir = homeDir.appending(components: "Library", "Logs", "LiangYi")
  static let launchRecord = FileManager.default.temporaryDirectory.appendingPathComponent(
    "io.github.zhenkun26.inputmethod.EcholME.launch.json", conformingTo: .json)

  // swiftlint:disable:next cyclomatic_complexity
  static func main() {
    let rimeAPI: RimeApi_stdbool = rime_get_api_stdbool().pointee

    let exitCode: Int32? = autoreleasepool {
      let installer = SquirrelInstaller()
      let args = CommandLine.arguments
      if args.count > 1 {
        let commandsWithModeArguments = ["--enable-input-source", "--disable-input-source", "--select-input-source"]
        if args.count > 2 && !commandsWithModeArguments.contains(args[1]) {
          reportCommandError("This command does not accept additional arguments. Use --help for supported commands.")
          return EXIT_FAILURE
        }
        switch args[1] {
        case "--quit":
          let bundleId = Bundle.main.bundleIdentifier!
          let runningSquirrels = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
          runningSquirrels.forEach { $0.terminate() }
          return EXIT_SUCCESS
        case "--reload":
          // Squirrel is a background app, and AppKit suspends distributed-notification delivery to inactive apps;
          // deliverImmediately is required for these notifications to reach Squirrel while it stays in the background
          DistributedNotificationCenter.default().postNotificationName(EcholMENotification.reload, object: nil, userInfo: nil, deliverImmediately: true)
          return EXIT_SUCCESS
        case "--register-input-source", "--install":
          return installer.register() ? EXIT_SUCCESS : EXIT_FAILURE
        case "--enable-input-source":
          guard let modes = parseModes(args.dropFirst(2)) else {
            return EXIT_FAILURE
          }
          return installer.enable(modes: modes) ? EXIT_SUCCESS : EXIT_FAILURE
        case "--disable-input-source":
          guard let modes = parseModes(args.dropFirst(2)) else {
            return EXIT_FAILURE
          }
          return installer.disable(modes: modes) ? EXIT_SUCCESS : EXIT_FAILURE
        case "--select-input-source":
          guard args.count <= 3, let modes = parseModes(args.dropFirst(2)) else {
            reportCommandError("Select accepts at most one EcholME input source ID.")
            return EXIT_FAILURE
          }
          return installer.select(mode: modes.first) ? EXIT_SUCCESS : EXIT_FAILURE
        case "--build":
          // Deployment maintains generated files. Use decoded filesystem paths;
          // URL.path() otherwise percent-encodes spaces such as Application Support.
          SquirrelApplicationDelegate.showMessage(msgText: NSLocalizedString("deploy_update", comment: ""))
          var builderTraits = RimeTraits.rimeStructInit()
          builderTraits.setCString("liangyi.echolme-builder", to: \.app_name)
          builderTraits.setCString(Bundle.main.sharedSupportPath!, to: \.shared_data_dir)
          builderTraits.setCString(userDir.path(percentEncoded: false), to: \.user_data_dir)
          builderTraits.setCString(logDir.path(percentEncoded: false), to: \.log_dir)
          rimeAPI.setup(&builderTraits)
          rimeAPI.deployer_initialize(nil)
          return rimeAPI.deploy() ? EXIT_SUCCESS : EXIT_FAILURE
        case "--sync":
          DistributedNotificationCenter.default().postNotificationName(EcholMENotification.sync, object: nil, userInfo: nil, deliverImmediately: true)
          return EXIT_SUCCESS
        case "--ascii":
          DistributedNotificationCenter.default().postNotificationName(EcholMENotification.toggleASCII, object: "ascii", userInfo: nil, deliverImmediately: true)
          return EXIT_SUCCESS
        case "--nascii":
          DistributedNotificationCenter.default().postNotificationName(EcholMENotification.toggleASCII, object: "nascii", userInfo: nil, deliverImmediately: true)
          return EXIT_SUCCESS
        case "--getascii":
          var responseReceived = false
          var asciiStatus = ""
          let observer = DistributedNotificationCenter.default().addObserver(
            forName: EcholMENotification.asciiResponse,
            object: nil,
            queue: .main
          ) { notification in
            if let status = notification.object as? String {
              asciiStatus = status
              responseReceived = true
            }
          }
          DistributedNotificationCenter.default().postNotificationName(EcholMENotification.getASCII, object: nil, userInfo: nil, deliverImmediately: true)
          let timeout = Date().addingTimeInterval(2.0)
          while !responseReceived && Date() < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
          }
          DistributedNotificationCenter.default().removeObserver(observer)
          if responseReceived {
            print(asciiStatus)
            return EXIT_SUCCESS
          } else {
            reportCommandError("No ASCII mode response received from EcholME.")
            return EXIT_FAILURE
          }
        case "--help":
          print(helpDoc)
          return EXIT_SUCCESS
        default:
          reportCommandError("Unknown argument. Use --help for supported commands.")
          return EXIT_FAILURE
        }
      }
      return nil
    }
    if let exitCode {
      exit(exitCode)
    }

    autoreleasepool {
      let main = Bundle.main
      let connectionName = main.object(forInfoDictionaryKey: "InputMethodConnectionName") as! String
      _ = IMKServer(name: connectionName, bundleIdentifier: main.bundleIdentifier!)
      let app = NSApplication.shared
      let delegate = SquirrelApplicationDelegate()
      app.delegate = delegate
      app.setActivationPolicy(.accessory)

      // OpenCC uses relative dictionary paths from SharedSupport.
      FileManager.default.changeCurrentDirectoryPath(main.sharedSupportPath!)

      if NSApp.squirrelAppDelegate.problematicLaunchDetected() {
        print("Problematic launch detected!")
        let args = ["Problematic launch detected! EcholME may be suffering a crash due to improper configuration. Revert previous modifications to see if the problem recurs."]
        let task = Process()
        task.executableURL = "/usr/bin/say".withCString { dir in
          URL(fileURLWithFileSystemRepresentation: dir, isDirectory: false, relativeTo: nil)
        }
        task.arguments = args
        try? task.run()
      } else {
        NSApp.squirrelAppDelegate.setupRime()
        NSApp.squirrelAppDelegate.startRime(fullCheck: false)
        NSApp.squirrelAppDelegate.loadSettings()
        print("EcholME reporting!")
      }

      app.run()
      print("EcholME is quitting...")
      rimeAPI.finalize()
    }
    return
  }

  private static func parseModes(_ arguments: ArraySlice<String>) -> [SquirrelInstaller.InputMode]? {
    var modes: [SquirrelInstaller.InputMode] = []
    for argument in arguments {
      guard let mode = SquirrelInstaller.InputMode(rawValue: argument) else {
        reportCommandError("Unknown EcholME input source ID: \(argument)")
        return nil
      }
      modes.append(mode)
    }
    return modes
  }

  static func reportCommandError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
  }

  static let helpDoc = """
Supported arguments:
Perform actions:
  --quit                     quit EcholME processes only
  --reload                   request deployment (delivery is not an acknowledgment)
  --sync                     sync user data
  --build                    deploy schemas into EcholME's Rime user directory
  --ascii                    turn on ASCII mode
  --nascii                   turn off ASCII mode
  --getascii                 get current ASCII mode status
Install EcholME:
  --install, --register-input-source    register this bundle; does not enable or select
  --enable-input-source [source id...]  input source list optional
  --disable-input-source [source id...] input source list optional
  --select-input-source [source id]     select an already enabled source
"""
}
