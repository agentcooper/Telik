//
//  QuickSearchItem.swift
//  Telik
//
//  Created by Artem Tyurin on 05/06/2022.
//

import SwiftUI

struct SelectionItem: QuickSearchItem {
  enum Kind {
    case source
    case tag
  }
  
  let id: String
  let label: String
  let kind: Kind
  
  func matches(_ searchText: String) -> Bool {
    return label.localizedCaseInsensitiveContains(searchText)
  }
  
  @ViewBuilder func body() -> some View {
    switch kind {
    case .source:
      Text(label)
    case .tag:
      Label(label, systemImage: "tag")
    }
  }
}
