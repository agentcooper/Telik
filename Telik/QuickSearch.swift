//
//  QuickSearch.swift
//  Telik
//
//  Created by Artem Tyurin on 05/06/2022.
//

import SwiftUI

protocol QuickSearchItem {
  associatedtype T: View
  
  func matches(_ searchText: String) -> Bool
  @ViewBuilder func body(_ searchText: String) -> T
}

typealias OnSelect<T> = (_ command: T, _ searchText: String) -> Void

struct QuickSearch<T: QuickSearchItem>: ViewModifier {
  let isPresented: Binding<Bool>
  let items: [T]
  let onSelect: OnSelect<T>
  
  func body(content: Content) -> some View {
    GeometryReader { geometry in
      content.sheet(isPresented: isPresented) {
        SearchView(items: items, onSelect: onSelect)
          .padding()
          .frame(width: geometry.size.width / 2, height: geometry.size.height / 1.5)
          .edgesIgnoringSafeArea(.all)
          .interactiveDismissDisabled(false)
      }
    }
  }
}

extension View {
  func quickSearch<T: QuickSearchItem>(isPresented: Binding<Bool>, items: [T], onSelect: @escaping OnSelect<T>)
  -> some View {
    modifier(QuickSearch(isPresented: isPresented, items: items, onSelect: onSelect))
  }
}

struct QuickSearchCommands: Commands {
  @Binding var showQuickSearch: Bool
  
  var body: some Commands {
    CommandMenu("Quick Search") {
      Button("Open Quick Search") {
        showQuickSearch.toggle()
      }
      .keyboardShortcut("p", modifiers: [.command])
      
      Button("Open Quick Search") {
        showQuickSearch.toggle()
      }
      .keyboardShortcut("o", modifiers: [.command])
    }
  }
}

fileprivate struct SearchView<T: QuickSearchItem>: View {
  @Environment(\.dismiss) var dismiss
  
  let items: [T]
  let onSelect: OnSelect<T>
  
  @State var selected: Int = 0
  @State var search: String = ""
  
  private var filteredResults: [T] {
    if search.isEmpty {
      return items
    }
    
    return items.filter { $0.matches(search) }
  }
  
  func down() {
    selected = min(selected + 1, filteredResults.endIndex - 1)
  }
  
  func up() {
    selected = max(selected - 1, 0)
  }
  
  func select() {
    if selected >= filteredResults.count {
      return
    }
    
    dismiss()
    onSelect(filteredResults[selected], search)
  }
  
  func cancel() {
    dismiss()
  }
  
  var body: some View {
    VStack {
      KeyboardTextField(text: $search, onDown: down, onUp: up, onEnter: select, onCancel: cancel)
        .onChange(of: search) { newValue in
          selected = 0
        }
      ScrollViewReader { proxy in
        ScrollView {
          // Causes "AttributeGraph: cycle detected through attribute",
          // can be switched to VStack.
          LazyVStack(spacing: 2) {
            ForEach(filteredResults.indices, id: \.self) { index in
              SelectableRow(isSelected: index == selected) {
                filteredResults[index].body(search)
              }
              .onTapGesture {
                selected = index
                select()
              }
            }
          }
        }
        .onChange(of: selected) { newValue in
          proxy.scrollTo(newValue)
        }
      }
    }
  }
}

fileprivate struct SelectableRow<Content: View>: View {
  let isSelected: Bool
  let viewBuilder: () -> Content
  
  var body: some View {
    viewBuilder()
      .padding(4)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundColor(isSelected ? Color(NSColor.highlightColor) : nil)
      .background(isSelected ? RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.accentColor) : nil)
      .contentShape(Rectangle())
  }
}

fileprivate struct KeyboardTextField: NSViewRepresentable {
  @Binding var text: String
  
  let onDown: () -> Void
  let onUp: () -> Void
  let onEnter: () -> Void
  let onCancel: () -> Void
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  func makeNSView(context: Context) -> NSTextField {
    let textField = NSTextField()
    textField.placeholderString = "Use ↑↓ to navigate, ⏎ to select"
    textField.delegate = context.coordinator
    textField.bezelStyle = NSTextField.BezelStyle.roundedBezel
    return textField
  }
  
  func updateNSView(_ nsView: NSTextField, context: Context) {
    nsView.stringValue = text
  }
  
  class Coordinator: NSObject, NSTextFieldDelegate {
    let parent: KeyboardTextField
    
    init(_ textField: KeyboardTextField) {
      self.parent = textField
    }
    
    func controlTextDidChange(_ obj: Notification) {
      guard let textField = obj.object as? NSTextField else { return }
      self.parent.text = textField.stringValue
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
      
      if commandSelector == #selector(NSTextView.moveDown(_:)) {
        self.parent.onDown()
        return true
      }
      
      if commandSelector == #selector(NSTextView.moveUp(_:)) {
        self.parent.onUp()
        return true
      }
      
      if commandSelector == #selector(NSTextView.insertNewline(_:)) {
        self.parent.onEnter()
        return true
      }
      
      if commandSelector == #selector(NSTextView.cancelOperation(_:)) {
        self.parent.onCancel()
        return true
      }
      
      return false
    }
  }
}
