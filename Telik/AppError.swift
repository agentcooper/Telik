//
//  AppError.swift
//  Telik
//
//  Created by Artem Tyurin on 27/05/2022.
//

import Foundation

enum AppError: Error, LocalizedError {
  case network(url: URL)
  case unknown(message: String)
}

extension AppError {
  public var errorDescription: String? {
    switch self {
    case .network(url: let url):
      return "Error fetching \(url)"
    case .unknown(message: let message):
      return "Unknown error: \(message)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .network(url: _):
      return "Check your internet connection."
    case .unknown(message: _):
      return nil
    }
  }
}
