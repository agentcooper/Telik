//
//  ContentView.swift
//  Telik
//
//  Created by Artem Tyurin on 01/05/2022.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var model: Model
  @Environment(\.openURL) var openURL
  
  @Binding var showExport: Bool
  @Binding var showAdd: Bool
  @Binding var showQuickSearch: Bool
  
  @State var selection = Set([allSources])
  @State var selectedTag: Source? = nil
  
  func add() {
    showAdd.toggle()
  }
  
  var filteredVideos: [Video] {
    if selection.contains(allSources) {
      return model.videos
    }
    
    let byId: [Source.ID: Source] = model.sources.reduce(into: [:], { result, item in
      result[item.id] = item
    })
    
    return model.videos.filter {
      if let source = byId[$0.channelId] {
        if !selection.isDisjoint(with: Set(source.tags)) {
          return true
        }
      }
      return selection.contains($0.channelId)
    }
  }
  
  var selectedIndices: IndexSet {
    IndexSet(model.sources.enumerated().compactMap { (index, element) in
      if selection.contains(element.id) {
        return index
      }
      return nil
    })
  }
  
  func deleteSelected() {
    if selectedIndices.isEmpty {
      return
    }
    
    guard Alert.confirm(title: "Are you sure you want to delete these sources?") else {
      return
    }
    
    let selectedSourceIds = Set(selectedIndices.map { model.sources[$0].id })
    
    model.videos = model.videos.filter { video in
      !selectedSourceIds.contains(video.channelId)
    }
    model.sources.remove(atOffsets: selectedIndices)
    
    model.save()
  }
  
  func selectionItems() -> [SelectionItem] {
    model.tags.map {
      SelectionItem(id: $0, label: $0, kind: .tag)
    }
    +
    model.sources.map {
      SelectionItem(id: $0.id, label: $0.label, kind: .source)
    }
    +
    [SelectionItem(id: "search", label: "Search", kind: .search)]
  }
  
  var body: some View {
    NavigationView {
      List(selection: $selection) {
        Label(allSources, systemImage: "tray.2").tag(allSources)
        
        if !model.tags.isEmpty {
          Section(header: Text("Tags")) {
            ForEach(model.tags, id: \.self) { tagName in
              Label(tagName, systemImage: "tag")
                .tag(tagName)
                .contextMenu {
                  tagContextMenuItems(tagName: tagName)
                }
            }
          }
        }
        
        Section(header: Text(allSources)) {
          ForEach(model.sources.sorted()) { source in
            Text(source.label).tag(source.id)
              .contextMenu {
                sourceContextMenuItems(source: source)
              }
          }
        }
      }
      .onDeleteCommand(perform: deleteSelected)
      .listStyle(SidebarListStyle())
      .alert(isPresented: .constant(model.appError != nil), error: model.appError) {_ in
        Button("OK") {
          model.appError = nil
        }
      } message: { error in
        if let recoverySuggestion = error.recoverySuggestion {
          Text(recoverySuggestion)
        }
      }
      .accentColor(.red)
      .frame(minWidth: 200)
      .listStyle(.sidebar)
      .toolbar {
        Button(action: add) {
          Image(systemName: "plus")
        }
        .help("Add…")
        Button(action: {
          Task {
            await model.fetchVideos()
          }
        }) {
          Image(systemName: "arrow.clockwise.circle")
            .opacity(model.isLoading ? 0 : 1)
            .overlay(alignment: .center) {
              if model.isLoading {
                ProgressView().progressViewStyle(.circular).scaleEffect(0.5)
              } else {
                EmptyView()
              }
            }
        }
        .help("Refresh")
        .keyboardShortcut("r", modifiers: [.command])
      }
      if !model.sources.isEmpty {
        Videos(videos: filteredVideos)
      } else {
        Text("No sources available. Press ⌘N to add.")
          .font(.title)
          .foregroundColor(Color.gray)
      }
    }
    .task() {
      await model.fetchVideos()
    }
    .sheet(isPresented: $showExport) {
      ExportView()
    }
    .sheet(isPresented: $showAdd) {
      AddView()
    }
    .sheet(isPresented: Binding(
      get: { self.selectedTag != nil },
      set: {
        if !$0 {
          self.selectedTag = nil
        }
      }
    )) {
      TagView(selection: $selection, selectedTag: $selectedTag)
    }
    .quickSearch(isPresented: $showQuickSearch, items: selectionItems()) { (selectedSource, searchText) in
      switch selectedSource.kind {
      case .search:
        if let searchURL = Search.getSearchURL(query: searchText) {
          openURL(searchURL)
        }
      default:
        selection = [selectedSource.id]
      }
    }
    .handlesExternalEvents(preferring: [URLScheme.prefix], allowing: [URLScheme.prefix])
    .onOpenURL { url in
      switch URLScheme.handleURL(url) {
      case .selectById(let id): selection = [id]
      case .selectByTag(let tag): selection = [tag]
      case .selectByTitle(let title):
        guard let source = model.sources.first(where: { $0.title == title }) else {
          break;
        }
        selection = [source.id]
      case .none:
        break;
      }
    }
  }
  
  @ViewBuilder
  func tagContextMenuItems(tagName: String) -> some View {
    Button {
      for (index, source) in model.sources.enumerated() {
        model.sources[index].tags = source.tags.filter {
          $0 != tagName
        }
      }
      model.save()
    } label: {
      Text("Delete tag")
    }
    Button {
      guard let newTagName = Alert.prompt(title: "Rename tag", question: "Enter new tag name for tag '\(tagName)'", defaultValue: "") else {
        return
      }
      
      for (index, source) in model.sources.enumerated() {
        model.sources[index].tags = source.tags.map {
          if $0 == tagName {
            return newTagName
          }
          return $0
        }
      }
      
      if selection == [tagName] {
        selection = [newTagName]
      }
      
      model.save()
    } label: {
      Text("Rename tag…")
    }
  }
  
  @ViewBuilder
  func sourceContextMenuItems(source: Source) -> some View {
    Button {
      openURL(URL(string: source.getYouTubeURL())!)
    } label: {
      Text("Open on YouTube")
    }
    
    Divider()
    
    Button {
      selectedTag = source
    } label: {
      Text("Set tags…")
    }
    
    if !source.tags.isEmpty {
      Menu("Current tags") {
        ForEach(source.tags, id: \.self) { tag in
          Text(tag)
        }
      }
    }
    
    Divider()
    
    Button {
      copyToClipBoard(textToCopy: source.getYouTubeURL())
    } label: {
      Text("Copy YouTube URL")
    }
    
    Button {
      copyToClipBoard(textToCopy: source.getFeedURL().absoluteString)
    } label: {
      Text("Copy feed URL")
    }
    
    Divider()
    
    Button("Delete…") {
      deleteSelected()
    }
  }
}
