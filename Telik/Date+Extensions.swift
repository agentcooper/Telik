//
//  Date+Extensions.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import Foundation

extension Date {
  func timeAgoDisplay() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: self, relativeTo: Date())
  }
}
