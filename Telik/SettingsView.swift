//
//  SettingsView.swift
//  Telik
//
//  Created by Artem Tyurin on 25/05/2022.
//

import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var model: Model
  @Environment(\.openURL) var openURL
  
  @State var selection = Set<String>()
  
  func deleteSelection() {
    model.sources = model.sources.filter {
      return !selection.contains($0.id)
    }
    model.save()
  }
  
  var body: some View {
    TabView {
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
    }
    .frame(width: 600, height: 400)
    .padding(20)
  }
}
