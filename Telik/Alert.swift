//
//  Alert.swift
//  Telik
//
//  Created by Artem Tyurin on 01/06/2022.
//

import Foundation
import SwiftUI

struct Alert {
  static func prompt(title: String, question: String, defaultValue: String) -> String? {
    let msg = NSAlert()
    msg.addButton(withTitle: "OK")
    msg.addButton(withTitle: "Cancel")
    msg.messageText = title
    msg.informativeText = question
    
    let txt = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
    txt.stringValue = defaultValue
    
    msg.window.initialFirstResponder = txt
    msg.accessoryView = txt
    
    if (msg.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn) {
      return txt.stringValue
    }
    
    return nil
  }
  
  static func confirm(title: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = title
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .warning
    return alert.runModal() == .alertFirstButtonReturn
  }
}


