//
//  Store.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import SwiftUI

let allSources = "All sources"
let uncategorized = "Uncategorized"

struct Feed {
  let videos: [Video]
}

struct Video: Identifiable, Equatable {
  let id: String
  let title: String
  let published: Date
  let thumbnail: String
  let channelTitle: String
  let channelId: String
  
  func toMarkdown() -> String {
    return markdownLink(title, getStandardYouTubeURL().absoluteString)
  }
  
  func getStandardYouTubeURL() -> URL {
    return URL(string: "https://www.youtube.com/watch?v=\(id)")!
  }
}

public enum SourceType: String, Codable {
  case channel
  case playlist
  case user
}

public struct Source: Codable, Identifiable, Equatable, Comparable {
  public static func < (lhs: Source, rhs: Source) -> Bool {
    return lhs.label.compare(rhs.label, options: .caseInsensitive) == .orderedAscending
  }
  
  public let id: String
  public let type: SourceType
  public var title: String?
  public var tags: [String] = []
  
  var label: String {
    return title ?? id
  }
  
  func getYouTubeURL() -> String {
    switch type {
    case .channel: return "https://www.youtube.com/channel/\(id)/videos"
    case .playlist: return "https://www.youtube.com/playlist?list=\(id)"
    case .user: return "https://www.youtube.com/user/\(id)"
    }
  }
  
  func getFeedURL() -> URL {
    switch type {
    case .channel:
      return URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(id)")!
    case .user:
      return URL(string: "https://www.youtube.com/feeds/videos.xml?user=\(id)")!
    case .playlist:
      return URL(string: "https://www.youtube.com/feeds/videos.xml?playlist_id=\(id)")!
    }
  }
}

struct SourceInfo {
  let id: String
  let title: String
  let videos: [Video]
}

@MainActor class Model: ObservableObject {
  let api = API()
  
  @Published var sources: [Source] = []
  @Published var videos = [Video]()
  @Published var isLoading = false
  @Published var appError: AppError?
  
  @Published var selectedVideo: Video.ID?
  
  @AppStorage("openMode") public var selectedDomain = OpenMode.fullScreenNoCookie
  
  var tags: [String] {
    Set(sources.flatMap { $0.tags }).sorted()
  }
  
  static func fileURL() throws -> URL {
    try FileManager.default.url(for: .documentDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: false)
    .appendingPathComponent("data.json")
  }
  
  static func load() -> [Source] {
    do {
      let fileURL = try fileURL()
      print(fileURL)
      guard let file = try? FileHandle(forReadingFrom: fileURL) else {
        return []
      }
      
      let channels = try JSONDecoder().decode([Source].self, from: file.availableData)
      
      return channels
    } catch {
      
      print(error)
      return []
    }
  }
  
  func save() {
    do {
      let data = try JSONEncoder().encode(sources)
      let outfile = try Model.fileURL()
      try data.write(to: outfile)
      print("Saved", outfile)
    } catch {
      print(error)
    }
  }
  
  func fetchVideos() async {
    defer {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.isLoading = false
      }
    }
    
    do {
      isLoading = true
      let videosBySource = await api.loadData(sources: sources)
      
      var sourceInfos = [SourceInfo]()
      var appErrors = [AppError]()
      
      for result in videosBySource.values {
        switch result {
        case .success(let sourceInfo):
          sourceInfos.append(sourceInfo)
        case .failure(let appError):
          appErrors.append(appError)
        }
      }
      
      let allVideos = sourceInfos.flatMap { sourceInfo in
        sourceInfo.videos
      }.sorted { $0.published > $1.published }
      
      // update channel titles
      for (index, source) in sources.enumerated() {
        let sourceInfo = videosBySource[source.id]
        
        if let sourceInfo = try? sourceInfo?.get(), sources[index].title == nil {
          sources[index].title = sourceInfo.title
        }
      }
      
      save()
      
      self.videos = allVideos
      
      // @TODO: figure out how to show all errors
      if let first = appErrors.first {
        self.appError = first
      }
    }
  }
  
  func addSource(_ source: Source) {
    let existingIds = Set(sources.map { $0.id })
    if !existingIds.contains(source.id) {
      sources.append(source)
    }
  }
  
  func markdownExport(exportTags: Bool) -> String {
    var result = "";
    for (index, source) in sources.enumerated() {
      let tags = source.tags.map { "#\($0)" }.joined(separator: " ")
      
      let line = "\(index + 1). \(markdownLink(source.label, source.getYouTubeURL())) \(exportTags ? tags : "")".trimmingCharacters(in: .whitespaces)
      
      result += "\(line)\n"
    }
    return result.trimmingCharacters(in: .whitespaces)
  }
  
  func getYouTubeURL(_ video: Video) -> URL {
    switch selectedDomain {
    case .fullScreenNoCookie:
      return URL(string: "https://www.youtube-nocookie.com/embed/\(video.id)?rel=0&autoplay=1")!
    case .fullScreen:
      return URL(string: "https://www.youtube.com/embed/\(video.id)?rel=0&autoplay=1")!
    case .usual:
      return video.getStandardYouTubeURL()
    }
  }
}
