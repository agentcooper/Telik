//
//  SettingsView.swift
//  Telik
//
//  Created by Artem Tyurin on 25/05/2022.
//

import SwiftUI

enum OpenTarget: String, Identifiable, CaseIterable {
  case browser = "Browser"
  case webview = "Webview"

  var id: Self { self }
}

enum URLOption: String, Identifiable, CaseIterable {
  case embedNoCookie = "Embed (youtube-nocookie.com)"
  case embed = "Embed (youtube.com)"
  case standard = "Standard (youtube.com)"
  case customURL = "Custom URL"

  var id: Self { self }
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
  
  @ViewBuilder
  func urlOptionPicker(selection: Binding<URLOption>, customURL: Binding<String>) -> some View {
    Picker("URL", selection: selection) {
      ForEach(URLOption.allCases) { option in
        Text(option.rawValue).tag(option)
      }
    }
    if selection.wrappedValue == .customURL {
      TextField("Custom URL", text: customURL)
      Text("Use $URL for the full YouTube URL or $VIDEO_ID for the video ID")
        .font(.caption).foregroundStyle(.secondary)
    }
  }

  var body: some View {
    TabView {
      Form {
        Picker("Open videos in", selection: model.$openTarget) {
          ForEach(OpenTarget.allCases) { target in
            Text(target.rawValue).tag(target)
          }
        }

        if model.openTarget == .browser {
          urlOptionPicker(selection: model.$browserURLOption, customURL: $model.browserCustomURL)
        } else {
          urlOptionPicker(selection: model.$webviewURLOption, customURL: $model.webviewCustomURL)
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
