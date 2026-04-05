//
//  Date+Extensions.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import Foundation

private let relativeDateFormatter: RelativeDateTimeFormatter = {
  let formatter = RelativeDateTimeFormatter()
  formatter.unitsStyle = .full
  return formatter
}()

extension Date {
  func timeAgoDisplay() -> String {
    relativeDateFormatter.localizedString(for: self, relativeTo: Date())
  }
}
