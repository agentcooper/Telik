//
//  VideoPlayerWindow.swift
//  Telik

import SwiftUI
import WebKit

struct VideoPlayerRequest: Codable, Hashable {
  let url: URL
  let title: String
}

class VideoWebView: WKWebView {
  var onWindowClose: (() -> Void)?
  private var windowObserver: Any?

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let window = self.window {
      if let observer = windowObserver {
        NotificationCenter.default.removeObserver(observer)
      }
      windowObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.willCloseNotification,
        object: window,
        queue: .main
      ) { [weak self] _ in
        self?.onWindowClose?()
      }
    }
  }

  deinit {
    if let observer = windowObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}

struct WebView: NSViewRepresentable {
  let url: URL

  func makeNSView(context: Context) -> VideoWebView {
    let webView = VideoWebView()
    webView.onWindowClose = { [weak webView] in
      webView?.loadHTMLString("", baseURL: nil)
    }
    context.coordinator.load(url: url, in: webView)
    return webView
  }

  func updateNSView(_ webView: VideoWebView, context: Context) {
    context.coordinator.load(url: url, in: webView)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    private var currentURL: URL?

    func load(url: URL, in webView: WKWebView) {
      guard url != currentURL else { return }
      currentURL = url
      webView.load(URLRequest(url: url))
    }
  }
}

struct VideoPlayerView: View {
  let request: VideoPlayerRequest

  var body: some View {
    WebView(url: request.url)
      .frame(minWidth: 480, idealWidth: 960, minHeight: 270, idealHeight: 540)
      .navigationTitle(request.title)
  }
}
