//
//  TelikApp.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import SwiftUI

@main
struct TelikApp: App {
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) var openWindow
  @StateObject private var model = Model()
  
  @State var showExport: Bool = false
  @State var showAdd: Bool = false
  @State var showQuickSearch: Bool = false
  
  func load() {
    model.sources = Model.load()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView(showExport: $showExport, showAdd: $showAdd, showQuickSearch: $showQuickSearch)
        .environmentObject(model)
        .onAppear(perform: load)
        .frame(minWidth: 700, idealWidth: 800, minHeight: 600, idealHeight: 900)
        .task {
#if CHECK_FOR_UPDATES
          if (model.automaticCheckForUpdates) {
            await model.appUpdate.checkForUpdatesWithPopup()
          }
#endif
        }
    }.commands {
      SidebarCommands()
      CommandMenu("Video") {
        Button("Open") {
          if let video = model.videos.first(where: { $0.id == model.selectedVideo }) {
            switch model.videoOpenIntent(for: video) {
            case .browser(let url): openURL(url)
            case .webview(let request): openWindow(value: request)
            }
          }
        }.keyboardShortcut(.return, modifiers: [])
      }
      CommandGroup(replacing: CommandGroupPlacement.newItem) {
        Button("Add…") {
          showAdd.toggle()
        }.keyboardShortcut("n", modifiers: [.command])
      }
      CommandGroup(after: CommandGroupPlacement.newItem) {
        Button("Export as Markdown…") {
          showExport.toggle()
        }.keyboardShortcut("e", modifiers: [.command])
      }
      QuickSearchCommands(showQuickSearch: $showQuickSearch)
    }
    WindowGroup("Video Player", for: VideoPlayerRequest.self) { $request in
      if let request {
        VideoPlayerView(request: request)
      }
    }
    .defaultSize(width: 960, height: 540)
    Settings {
      SettingsView()
        .environmentObject(model)
    }
  }
}

func copyToClipBoard(textToCopy: String) {
  let pasteBoard = NSPasteboard.general
  pasteBoard.clearContents()
  pasteBoard.setString(textToCopy, forType: .string)
}
