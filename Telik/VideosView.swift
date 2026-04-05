//
//  VideosView.swift
//  Telik
//
//  Created by Artem Tyurin on 06/05/2022.
//

import SwiftUI
import UniformTypeIdentifiers

struct Videos: View {
  @EnvironmentObject var model: Model
  
  @State private var searchText = ""
  
  let videos: [Video]
  
  var filteredVideos: [Video] {
    if searchText.isEmpty {
      return videos
    }
    
    return videos.filter { video in video.title.localizedCaseInsensitiveContains(searchText) || video.channelTitle.localizedCaseInsensitiveContains(searchText) }
  }
  
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(filteredVideos) { video in
          VideoView(video: video)
        }
      }.padding()
    }
    .searchable(text: $searchText, prompt: "Search videos")
    .onChange(of: filteredVideos) { newValue in
      model.selectedVideo = newValue.first?.id
    }
  }
}

struct VideoView: View {
  @EnvironmentObject var model: Model
  @Environment(\.openURL) var openURL
  @Environment(\.openWindow) var openWindow
  @Environment(\.showChannel) var showChannel
  
  let video: Video
  
  var body: some View {
    HStack() {
      CacheAsyncImage(url: URL(string: video.thumbnail)!, fallbackURL: URL(string: video.thumbnailFallback)!) {
        phase in
        switch(phase) {
        case .success(let image):
          image.resizable().aspectRatio(contentMode: .fill)
        case .failure:
          Image(systemName: "wifi.slash")
        default:
          ProgressView()
        }
      }
      .id(video.thumbnail)
      .frame(width: 160, height: 90)
      .clipped()
      
      VStack(alignment: .leading) {
        Text(video.title).font(.title2)
        Text(video.channelTitle)
        Text(video.published.timeAgoDisplay())
          .foregroundColor(Color(NSColor.lightGray))
          .padding(.vertical, 4)
      }.frame(maxWidth: .infinity, alignment: .leading)
    }
    .tag(video.id)
    .frame(height: 90)
    .contentShape(Rectangle())
    .onTapGesture {
      switch model.videoOpenIntent(for: video) {
      case .browser(let url): openURL(url)
      case .webview(let request): openWindow(value: request)
      }
    }
    .contextMenu {
      Button {
        showChannel(video.channelId)
      } label: {
        Text("Show channel")
      }
      
      Divider()
      
      Button {
        switch model.videoOpenIntent(for: video) {
        case .browser(let url): copyToClipBoard(textToCopy: url.absoluteString)
        case .webview(let request): copyToClipBoard(textToCopy: request.url.absoluteString)
        }
      } label: {
        Text("Copy URL")
      }
      Button {
        copyToClipBoard(textToCopy: video.getStandardYouTubeURL().absoluteString)
      } label: {
        Text("Copy YouTube URL")
      }
      Button {
        copyToClipBoard(textToCopy: video.toMarkdown())
      } label: {
        Text("Copy as Markdown")
      }
      
      Divider()

      ShareMenu(url: video.getStandardYouTubeURL())
    }
  }
}

struct ShareMenu: View {
  let url: URL

  var body: some View {
    let services = NSSharingService.sharingServices(forItems: [url])
    ForEach(services, id: \.title) { service in
      Button(action: {
        service.perform(withItems: [url])
      }) {
        Image(nsImage: service.image)
        Text(service.title)
      }
    }
  }
}
