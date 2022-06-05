//
//  API.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import SwiftUI
import SWXMLHash

func throwError<T>(_ error: Error) throws -> T {
  throw error
}

class API: ObservableObject {
  let newFormatter = ISO8601DateFormatter()
  
  let session = URLSession.shared
  
  func loadSource(_ source: Source) async -> Result<SourceInfo, AppError> {
    var videos = [Video]()
    
    let url = source.getFeedURL()
    guard let (data, _) = try? await session.data(from: url) else {
      return .failure(AppError.network(url: url))
    }
    let content = String(bytes: data, encoding: String.Encoding.utf8)!
    let xml = XMLHash.parse(content)
    
    let feed = xml["feed"]
    let parseError = AppError.parse(source: source, content: content)
    
    guard let title = feed["title"].element?.text else {
      return .failure(parseError)
    }
    
    do {
      for entry in feed["entry"].all {
        guard let id = entry["yt:videoId"].element?.text else {
          return .failure(AppError.parse(source: source, content: content))
        }
        
        let mediaGroup = entry["media:group"]
        
        let published = try entry["published"].element?.text ?? throwError(parseError)
        
        let video = Video(
          id: id,
          title: try mediaGroup["media:title"].element?.text ?? throwError(parseError),
          published: try newFormatter.date(from: published) ?? throwError(parseError),
          thumbnail: try mediaGroup["media:thumbnail"].element?.attribute(by: "url")?.text ?? throwError(parseError),
          channelTitle: title,
          channelId: source.id
        )
        
        videos.append(video)
      }
    } catch {
      return .failure(parseError)
    }
    
    return .success(SourceInfo(id: source.id, title: title, videos: videos))
  }
  
  func loadData(sources: [Source]) async -> [String: Result<SourceInfo, AppError>]  {
    let results = await withTaskGroup(of: (String, Result<SourceInfo, AppError>).self) { group -> [String: Result<SourceInfo, AppError>] in
      for source in sources {
        group.addTask {
          let result = await self.loadSource(source)
          return (source.id, result)
        }
      }
      
      var collected = [String: Result<SourceInfo, AppError>]()
      
      for await (id, channelInfo) in group {
        collected[id] = channelInfo
      }
      
      return collected
    }
    
    return results
  }
}
