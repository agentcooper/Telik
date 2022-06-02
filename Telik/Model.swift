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
  
  func getYouTubeURL() -> URL {
    return URL(string: "https://www.youtube-nocookie.com/embed/\(id)?rel=0&autoplay=1")!
  }
  
  func toMarkdown() -> String {
    return markdownLink(title, getYouTubeURL().absoluteString)
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
  
  @Published var selectedVideo: String?
  
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
      let videosBySource = try await api.loadData(sources: sources)
      
      let allVideos = videosBySource.values.flatMap { $0.videos }.sorted { $0.published > $1.published }
      
      // update channel titles
      for (index, channel) in sources.enumerated() {
        let channelInfo = videosBySource[channel.id]
        
        if let channelInfo = channelInfo, sources[index].title == nil {
          sources[index].title = channelInfo.title
        }
      }
      
      save()
      
      self.videos = allVideos
    } catch let appError as AppError {
      self.appError = appError
    } catch {
      self.appError = AppError.unknown(message: error.localizedDescription)
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
}
