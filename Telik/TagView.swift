//
//  TagView.swift
//  Telik
//
//  Created by Artem Tyurin on 30/05/2022.
//

import SwiftUI

struct TagView: View {
  @EnvironmentObject var model: Model
  
  @Binding var selection: Set<String>
  @Binding var selectedTag: Source?
  
  @State var tagInput = ""
  
  var body: some View {
    VStack {
      TextField("Tags (separated by comma or space)", text: $tagInput)
        .onSubmit {
          let indices: [Array.Index] = model.sources.enumerated().compactMap { (index, element) in
            
            if element == selectedTag {
              return index
            }
            
            if selection.contains(element.id) {
              return index
            }
            return nil
          }
          
          let tags: [String] = tagInput.components(separatedBy: CharacterSet(charactersIn: ", ")).compactMap {
            let trimmmed = $0.trimmingCharacters(in: .whitespaces)
            if trimmmed.isEmpty {
              return nil
            }
            return trimmmed
          }
          
          for index in indices {
            model.sources[index].tags = tags
          }
          model.save()
          
          selection = Set(tags)
          selectedTag = nil
        }
    }
    .onAppear {
      tagInput = ""
    }
    .padding()
    .frame(minWidth: 400)
    .onExitCommand {
      selectedTag = nil
    }
  }
}
