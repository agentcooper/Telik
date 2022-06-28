//
//  ShowChannelAction.swift
//  Telik
//
//  Created by Artem Tyurin on 28/06/2022.
//

import SwiftUI

private struct ShowChannelAction: EnvironmentKey {
  static func defaultShowChannel(_ channelId: String) {}
  static let defaultValue = defaultShowChannel
}

extension EnvironmentValues {
  var showChannel: (_ channelId: String) -> Void {
    get { self[ShowChannelAction.self] }
    set { self[ShowChannelAction.self] = newValue }
  }
}
