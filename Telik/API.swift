//
//  API.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import SwiftUI
import SWXMLHash

class API: ObservableObject {
  let newFormatter = ISO8601DateFormatter()
  
  let session = URLSession.shared
  
  func getURL(_ source: Source) -> URL {
    switch source.type {
    case .playlist: return getPlaylistFeedURL(source.id)
    case .channel: return getChannelFeedURL(source.id)
    }
  }
  
  func loadSource(_ source: Source) async throws -> SourceInfo {
    var videos = [Video]()
    
    let url = getURL(source)
    guard let (data, _) = try? await session.data(from: url) else {
      throw AppError.network(url: url)
    }
    let content = String(bytes: data, encoding: String.Encoding.utf8)!
    let xml = XMLHash.parse(content)
    
    let feed = xml["feed"]
    let title = feed["title"].element!.text
    
    for entry in feed["entry"].all {
      let id = entry["yt:videoId"].element!.text
      let mediaGroup = entry["media:group"]
      
      let video = Video(
        id: id,
        title: mediaGroup["media:title"].element!.text,
        published: newFormatter.date(from: entry["published"].element!.text)!,
        thumbnail: mediaGroup["media:thumbnail"].element!.attribute(by: "url")!.text,
        channelTitle: title,
        channelId: source.id
      )
      
      videos.append(video)
    }
    
    return SourceInfo(id: source.id, title: title, videos: videos)
  }
  
  func loadData(sources: [Source]) async throws -> [String: SourceInfo]  {
    let videos = try await withThrowingTaskGroup(of: (String, SourceInfo).self) { group -> [String: SourceInfo] in
      for source in sources {
        group.addTask{
          let channelInfo = try await self.loadSource(source)
          
          return (source.id, channelInfo)
        }
      }
      
      var collected = [String: SourceInfo]()
      
      for try await (id, channelInfo) in group {
        collected[id] = channelInfo
      }
      
      return collected
    }
    
    return videos
  }
  
  // https://m.youtube.com/feeds/videos.xml?channel_id=UCx_IFO8jgb46QdmO6VGMRgQ
  func getChannelFeedURL(_ channelId: String) -> URL {
    return URL(string: "https://www.youtube.com/feeds/videos.xml?channel_id=\(channelId)")!
  }
  
  // https://www.youtube.com/feeds/videos.xml?playlist_id=PLMnzjxOFrGPnK_CtpsF6Qa_knNg7QyHzF
  func getPlaylistFeedURL(_ playlistId: String) -> URL {
    return URL(string: "https://www.youtube.com/feeds/videos.xml?playlist_id=\(playlistId)")!
  }
}
