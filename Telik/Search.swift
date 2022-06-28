//
//  Search.swift
//  Telik
//
//  Created by Artem Tyurin on 28/06/2022.
//

import Foundation

struct Search {
  static func getSearchURL(query: String) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "youtube.com"
    components.path = "/results"
    components.queryItems = [URLQueryItem(name: "search_query", value: query)]
    return components.url
  }
}
