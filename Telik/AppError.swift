//
//  AppError.swift
//  Telik
//
//  Created by Artem Tyurin on 27/05/2022.
//

import Foundation

enum AppError: Error, LocalizedError {
  case network(url: URL)
  case parse(source: Source, content: String)
  case unknown(message: String)
}

extension AppError {
  public var errorDescription: String? {
    switch self {
    case .network(url: let url):
      return "Error fetching \(url)"
    case .parse(source: let source, content: _):
      return "Error parsing response from \(source.label) (\(source.getFeedURL()))"
    case .unknown(message: let message):
      return "Unknown error: \(message)"
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .network(url: _):
      return "Check your internet connection."
    case .parse(source: _, content: let content):
      return "Try again in a few minutes.\n\nResponse:\n\n\(content)"
    case .unknown(message: _):
      return nil
    }
  }
}
