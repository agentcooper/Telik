//
//  CheckForUpdates.swift
//  Telik
//
//  Created by Artem Tyurin on 17/07/2022.
//

import SwiftUI
import SWXMLHash

struct AppUpdate {
  @Environment(\.openURL) var openURL
  
  @AppStorage("skippedVersions") private var skippedVersions: Set<String> = []
  @AppStorage("lastChecked") private var lastChecked: Date = Date.distantPast
  
  let githubURL: URL
  
  let cooldownInterval: TimeInterval = 60 * 60 * 24
  
  func checkForUpdatesWithPopup(force: Bool = false) async {
    if !force && Date.now.timeIntervalSince(lastChecked) < cooldownInterval {
      print("Skipping update check as the last update is within the cooldown time")
      return
    }
    
    guard let currentVersion = getCurrentVersion(), let appName = getAppName() else {
      print("Bundle data error")
      return
    }
    
    print("Fetching latest version...")
    guard let latestVersion = await fetchLatestVersion() else {
      return
    }
    print("Latest available version is \(latestVersion)")
    
    if currentVersion == latestVersion {
      print("Using latest version")
      
      if force {
        DispatchQueue.main.async {
          let alert = NSAlert()
          alert.messageText = "You're using latest version (\(latestVersion))."
          alert.runModal()
        }
      }
      
      return
    }
    
    if !force && skippedVersions.contains(latestVersion) {
      print("Version \(latestVersion) is skipped")
      return
    }
    
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = "A new version of \(appName) is available!"
      alert.informativeText = "\(appName) \(latestVersion) is now available – you have \(currentVersion)."
      alert.addButton(withTitle: "Open on GitHub")
      alert.addButton(withTitle: "Skip")
      alert.addButton(withTitle: "Remind me next time")
      
      switch alert.runModal() {
      case .alertFirstButtonReturn:
        lastChecked = Date.now
        openURL(downloadURL(version: latestVersion))
      case .alertSecondButtonReturn:
        lastChecked = Date.now
        skippedVersions.insert(latestVersion)
      default:
        break;
      }
    }
  }
  
  private func fetchLatestVersion() async -> String? {
    guard let (data, _) = try? await URLSession.shared.data(from: feedURL) else {
      print("Data error")
      return nil
    }
    
    let content = String(bytes: data, encoding: String.Encoding.utf8)!
    let xml = XMLHash.parse(content)
    let feed = xml["feed"]
    
    guard let latestEntry = feed["entry"].all.first else {
      print("Data error")
      return nil
    }
    
    let latestVersion = latestEntry["title"].element?.text
    
    return latestVersion
  }
  
  private var feedURL: URL {
    githubURL.appendingPathComponent("/releases.atom")
  }
  
  private func downloadURL(version: String) -> URL {
    githubURL.appendingPathComponent("/releases/tag/\(version)")
  }
  
  private func getCurrentVersion() -> String? {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
  }
  
  private func getAppName() -> String? {
    Bundle.main.infoDictionary?["CFBundleName"] as? String
  }
}

extension Set: RawRepresentable where Element == String {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(Set<String>.self, from: data)
    else {
      return nil
    }
    self = result
  }
  
  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension Date: RawRepresentable {
  public var rawValue: String {
    self.timeIntervalSinceReferenceDate.description
  }
  
  public init?(rawValue: String) {
    self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
  }
}
