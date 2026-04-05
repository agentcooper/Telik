//
//  CachedAsyncImage.swift
//  Telik
//
//  Created by Artem Tyurin on 01/05/2022.
//

import SwiftUI

struct CacheAsyncImage<Content>: View where Content: View {
  private let url: URL
  private let content: (AsyncImagePhase) -> Content

  @State private var phase: AsyncImagePhase

  init(
    url: URL,
    scale: CGFloat = 1.0,
    transaction: Transaction = Transaction(),
    @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
  ) {
    self.url = url
    self.content = content
    if let cached = ImageCache[url] {
      _phase = State(initialValue: .success(cached))
    } else {
      _phase = State(initialValue: .empty)
    }
  }

  var body: some View {
    content(phase)
      .task(id: url) {
        if let cached = ImageCache[url] {
          phase = .success(cached)
          return
        }

        do {
          let (data, _) = try await URLSession.shared.data(from: url)
          let image = try decodeImage(data)
          ImageCache[url] = image
          phase = .success(image)
        } catch {
          phase = .failure(error)
        }
      }
  }
}

private nonisolated func decodeImage(_ data: Data) throws -> Image {
  guard let nsImage = NSImage(data: data) else {
    throw URLError(.cannotDecodeContentData)
  }
  return Image(nsImage: nsImage)
}

fileprivate class ImageCache {
  static private var cache: [URL: Image] = [:]
  static subscript(url: URL) -> Image? {
    get {
      ImageCache.cache[url]
    }
    set {
      ImageCache.cache[url] = newValue
    }
  }
}
