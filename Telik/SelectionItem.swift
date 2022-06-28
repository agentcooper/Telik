//
//  QuickSearchItem.swift
//  Telik
//
//  Created by Artem Tyurin on 05/06/2022.
//

import SwiftUI

let toLatinMemo = memoize(toLatin)

struct SelectionItem: QuickSearchItem {
  enum Kind {
    case source
    case tag
    case search
  }
  
  let id: String
  let label: String
  let kind: Kind
  
  func matches(_ searchText: String) -> Bool {
    if kind == Kind.search {
      return true
    }
    
    return toLatin(label)?.localizedCaseInsensitiveContains(searchText) ?? false
  }
  
  @ViewBuilder func body(_ searchText: String) -> some View {
    switch kind {
    case .source:
      Text(label)
    case .tag:
      Label(label, systemImage: "tag")
    case .search:
      Label("Search YouTube for \"\(searchText)\"", systemImage: "magnifyingglass")
    }
  }
}

func toLatin(_ input: String) -> String? {
  let latinString = input.applyingTransform(StringTransform.toLatin, reverse: false)
  let noDiacriticString = latinString?.applyingTransform(StringTransform.stripDiacritics, reverse: false)
  return noDiacriticString
}

func memoize<Input: Hashable, Output>(_ function: @escaping (Input) -> Output) -> (Input) -> Output {
  var storage = [Input: Output]()
  
  return { input in
    if let cached = storage[input] {
      return cached
    }
    
    let result = function(input)
    storage[input] = result
    return result
  }
}
