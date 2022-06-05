//
//  URLScheme.swift
//  Telik
//
//  Created by Artem Tyurin on 05/06/2022.
//

import Foundation

enum Action {
  // telik:///select?id=UCYO_jab_esuFRV4b17AJtAw
  case selectById(_ id: String)
  
  // telik:///select?title=Better%20Ideas
  case selectByTitle(_ title: String)
  
  // telik:///select?tag=Computers
  case selectByTag(_ tag: String)
}

@MainActor struct URLScheme {
  static let prefix = "telik"
  
  static func handleURL(_ url: URL) -> Action? {
    guard let components = URLComponents(
      url: url,
      resolvingAgainstBaseURL: false
    ) else {
      return nil
    }
    
    switch (url.path) {
    case "/select":
      guard let queryItem = components.queryItems?.first else {
        break;
      }
      
      guard let queryValue = queryItem.value else {
        break;
      }
      
      switch (queryItem.name) {
      case "id":
        return .selectById(queryValue)
      case "title":
        return .selectByTitle(queryValue)
      case "tag":
        return .selectByTag(queryValue)
      default:
        print("Unknown query", queryItem)
      }
    default:
      break;
    }
    
    return nil
  }
}
