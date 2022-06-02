//
//  SettingsView.swift
//  Telik
//
//  Created by Artem Tyurin on 01/05/2022.
//

import SwiftUI

enum MyError: Error {
  case obvious
}

let js = """
let markdown = Array.from(document.querySelectorAll("ytd-channel-renderer"))
  .map((item) => ({
    title: item.querySelector("#text-container").textContent.trim(),
    url: item.querySelector("#main-link").href,
  }))
  .map(({ title, url }) => `- [${title}](${url})`)
  .join(String.fromCharCode(10));

document.write("Your clipboard now contains the list of your YouTube subscriptions.");
copy(markdown);
"""

struct ParseResult: Equatable {
  let url: URL
  let tags: [String]
}

struct AddView: View {
  @EnvironmentObject var model: Model
  
  @Environment(\.openURL) var openURL
  @Environment(\.dismiss) var dismiss
  
  @State private var fullText: String = ""
  @State private var isAdding = false
  
  func fetchChannelId(url: URL) async throws -> String {
    var request = URLRequest(url: url)
    request.setValue("CONSENT=YES+yt.442910462.en-GB+FX+105", forHTTPHeaderField: "cookie")
    request.httpShouldHandleCookies = true
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let content = String(bytes: data, encoding: String.Encoding.utf8)!
    
    let groups = content.groups(for: #"<meta itemprop="channelId" content="([a-zA-Z0-9_-]+)">"#)
    
    if groups.isEmpty {
      print("Error for \(url)")
      throw MyError.obvious
    }
    
    let channelId = groups.first![1]
    
    return channelId
  }
  
  func extractURLs(text: String) -> [(URL, NSRange)] {
    let types: NSTextCheckingResult.CheckingType = .link
    
    do {
      let detector = try NSDataDetector(types: types.rawValue)
      
      let matches = detector.matches(in: text, options: .reportCompletion, range: NSMakeRange(0, text.count))
      
      return matches.compactMap {
        if let url = $0.url {
          return (url, $0.range)
        }
        return nil
      }
    } catch let error {
      debugPrint(error.localizedDescription)
    }
    
    return []
  }
  
  func extractTags(line: String) -> [String] {
    let words = line.components(separatedBy: CharacterSet(charactersIn: ", "))
    var tags = [String]()
    for word in words {
      if word.hasPrefix("#") {
        let tag = word.dropFirst()
        tags.append(String(tag))
      }
    }
    return tags
  }
  
  func parseSources(input: String) -> [ParseResult] {
    var result = [ParseResult]()
    let lines = input.split(whereSeparator: \.isNewline)
    for line in lines {
      let line = String(line)
      let urls = extractURLs(text: line)
      guard let (url, range) = urls.first else {
        continue
      }
      let startIndex = line.index(line.startIndex, offsetBy: range.upperBound)
      let lineAfterURL = String(line[startIndex..<line.endIndex])
      let tags = extractTags(line: lineAfterURL)
      result.append(ParseResult(url: url, tags: tags))
    }
    return result
  }
  
  func addChannels() async {
    defer {
      isAdding = false
    }
    isAdding = true
    
    for parseResult in parseSources(input: fullText) {
      let url = parseResult.url
      let pathComponents = url.pathComponents
      
      if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        if let listValue = urlComponents.queryItems?.first(where: { $0.name == "list" })?.value {
          model.addSource(Source(id: listValue, type: .playlist, tags: parseResult.tags))
        }
      }
      
      if let index = pathComponents.firstIndex(of: "channel") {
        let channelId = pathComponents[index + 1]
        model.addSource(Source(id: channelId, type: .channel, tags: parseResult.tags))
      } else if let index = pathComponents.firstIndex(of: "user") {
        let userId = pathComponents[index + 1]
        model.addSource(Source(id: userId, type: .user, tags: parseResult.tags))
      } else {
        print("Fetching for \(parseResult)")
        
        do {
          let channelId = try await fetchChannelId(url: url)
          model.addSource(Source(id: channelId, type: .channel, tags: parseResult.tags))
        } catch {
          print("Could not fetch channelId", url, error)
        }
      }
    }
    
    model.save()
    
    dismiss()
    
    await model.fetchVideos()
  }
  
  var fileURL: String {
    do {
      return try Model.fileURL().absoluteString
    } catch {
      return ""
    }
  }
  
  var body: some View {
    TabView {
      VStack {
        Text("Paste any text containing links to YouTube channels or playlists:")
          .frame(maxWidth: .infinity)
        TextEditor(text: $fullText)
          .font(Font.system(.body, design: .monospaced))
        Button(action: {
          Task {
            await addChannels()
          }
        }) {
          Text("Add channels or playlists")
        }.keyboardShortcut(.return, modifiers: [.command])
      }
      .opacity(isAdding ? 0.3 : 1)
      .overlay(alignment: .center) {
        if isAdding {
          ProgressView()
        } else {
          EmptyView()
        }
      }
      .disabled(isAdding)
      .padding()
      .tabItem { Text("Add") }
      
      VStack {
        Text("Open https://www.youtube.com/feed/channels and paste to JS console:")
        TextEditor(text: .constant(js))
          .font(Font.system(.body, design: .monospaced))
        
        Text("[How to open JS console?](https://webmasters.stackexchange.com/questions/8525/how-do-i-open-the-javascript-console-in-different-browsers/77337#77337)")
          .font(.footnote)
      }
      .padding()
      .tabItem { Text("YouTube export guide") }
    }
    .padding()
    .frame(minWidth: 400, minHeight: 400)
    .onExitCommand {
      if !isAdding {
        dismiss()
      }
    }
  }
}
