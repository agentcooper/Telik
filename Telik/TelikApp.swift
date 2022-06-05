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
    }.commands {
      SidebarCommands()
      CommandMenu("Video") {
        Button("Open on YouTube") {
          if let video = model.videos.first(where: { $0.id == model.selectedVideo }) {
            openURL(video.getYouTubeURL())
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
