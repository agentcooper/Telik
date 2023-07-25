//
//  SettingsView.swift
//  Telik
//
//  Created by Artem Tyurin on 25/05/2022.
//

import SwiftUI

enum OpenMode: String, Identifiable, CaseIterable {
  case fullScreenNoCookie = "Full screen (youtube-nocookie.com)"
  case fullScreen = "Full screen (youtube.com)"
  case usual = "Usual (youtube.com)"
  case customURL = "Custom URL"
  
  var id: String { self.rawValue }
}

struct SettingsView: View {
  @EnvironmentObject var model: Model
  @Environment(\.openURL) var openURL
  
  @State var selection = Set<Source.ID>()
  
  func deleteSelection() {
    model.sources = model.sources.filter {
      return !selection.contains($0.id)
    }
    model.save()
  }
  
  var body: some View {
    TabView {
      Form {
        Picker("Open videos", selection: model.$selectedDomain) {
          ForEach(OpenMode.allCases) { domain in
            Text(domain.rawValue).tag(domain)
          }
        }
        if model.selectedDomain == .customURL {
          TextField("Custom URL", text: $model.customOpenCommand)
          Text("Use $URL for YouTube URL").font(.caption).foregroundColor(.gray)
        }
        Toggle(isOn: $model.hideShorts) {
          Text("Hide videos with #shorts in the title")
        }
      }
      .tabItem { Label("Viewing", systemImage: "eyeglasses") }
      
      Form {
        Text("Select one or multiple, use Delete key to delete.")
        List(model.sources, selection: $selection) {
          Text($0.title ?? $0.id)
        }
        .onDeleteCommand(perform: deleteSelection)
      }
      .tabItem { Label("Sources", systemImage: "list.triangle") }
      
      Form {
        VStack {
          Text("Use File > Export as Markdown…")
          
          Divider()
          
          Text("Or, you can find your local data in:")
          if let fileURL = try? Model.fileURL() {
            Button(fileURL.absoluteString) {
              NSWorkspace.shared.activateFileViewerSelecting([fileURL])
            }
          }
        }
      }
      .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
      
#if CHECK_FOR_UPDATES
      Form {
        VStack {
          Toggle(isOn: $model.automaticCheckForUpdates) {
            Text("Check for updates automatically")
          }
          
          Divider()
          
          Button("Check for updates...") {
            Task {
              await model.appUpdate.checkForUpdatesWithPopup(force: true)
            }
          }
        }
      }
      .tabItem { Label("Updates", systemImage: "icloud.and.arrow.down") }
#endif
    }
    .frame(width: 600, height: 400)
    .padding(20)
  }
}
