//
//  ExportView.swift
//  Telik
//
//  Created by Artem Tyurin on 25/05/2022.
//

import SwiftUI

struct ExportView: View {
  @EnvironmentObject var model: Model
  @Environment(\.dismiss) var dismiss
  
  @SceneStorage("ExportView.exportTags") var exportTags = true
  
  var body: some View {
    let content = model.markdownExport(exportTags: exportTags)
    
    VStack {
      Toggle(isOn: $exportTags) {
        Text("Export tags")
      }
      
      TextEditor(text: .constant(content))
        .font(Font.system(.body, design: .monospaced))
        .padding(4)
      
      Button("Copy to clipboard") {
        copyToClipBoard(textToCopy: content)
        dismiss()
      }.keyboardShortcut(.return, modifiers: [.command])
    }
    .padding()
    .frame(minWidth: 400, maxHeight: 400)
    .onExitCommand {
      dismiss()
    }
  }
}
