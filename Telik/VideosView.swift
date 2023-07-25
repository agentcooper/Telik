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
    // @TODO: at some point List should become lazy on macOS
    ScrollView {
      LazyVStack(alignment: .leading) {
        ForEach(filteredVideos) { video in
          VideoView(video: video)
        }
      }.padding()
    }
    .searchable(text: $searchText, prompt: "Search videos")
    .onChange(of: filteredVideos) { newValue in
      DispatchQueue.main.async {
        model.selectedVideo = newValue.first?.id
      }
    }
  }
}

struct VideoView: View {
  @EnvironmentObject var model: Model
  @Environment(\.openURL) var openURL
  @Environment(\.showChannel) var showChannel
  
  let video: Video
  
  var body: some View {
    HStack() {
      CacheAsyncImage(url: URL(string: video.thumbnail)!) {
        phase in
        switch(phase) {
        case .success(let image):
          image.resizable().aspectRatio(contentMode: .fit)
        case .failure:
          Image(systemName: "wifi.slash")
        default:
          ProgressView()
        }
      }
      .id(video.thumbnail)
      .frame(width: 120, height: 90)
      
      VStack(alignment: .leading) {
        Text(video.title).font(.title2)
        Text(video.channelTitle)
        Text(video.published.timeAgoDisplay())
          .foregroundColor(Color(NSColor.lightGray))
          .padding(.vertical, 4)
      }.frame(maxWidth: .infinity, alignment: .leading)
    }
    .tag(video.id)
    .background(.background)
    .cornerRadius(5)
    .frame(height: 90)
    .contentShape(Rectangle())
    .onTapGesture {
      openURL(model.getOpenURL(video))
    }
    .contextMenu {
      Button {
        showChannel(video.channelId)
      } label: {
        Text("Show channel")
      }
      
      Divider()
      
      Button {
        copyToClipBoard(textToCopy: model.getOpenURL(video).absoluteString)
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
      
      let sharingItem = video.getStandardYouTubeURL()
      let services = NSSharingService.sharingServices(forItems: [sharingItem])
      ForEach(services, id: \.title) { service in
        Button(action: {
          service.perform(withItems: [sharingItem])
        }) {
          Image(nsImage: service.image)
          Text(service.title)
        }
      }
    }
  }
}
