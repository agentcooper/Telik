//
//  VideoPlayerWindow.swift
//  Telik

import SwiftUI
import WebKit

struct VideoPlayerRequest: Codable, Hashable {
  let url: URL
  let title: String
  let useLocalServer: Bool

  init(url: URL, title: String, useLocalServer: Bool) {
    self.url = url
    self.title = title
    self.useLocalServer = useLocalServer
  }

  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    self.url = try c.decode(URL.self, forKey: .url)
    self.title = try c.decode(String.self, forKey: .title)
    self.useLocalServer = try c.decodeIfPresent(Bool.self, forKey: .useLocalServer) ?? true
  }
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
  let useLocalServer: Bool

  func makeNSView(context: Context) -> VideoWebView {
    let webView = VideoWebView()
    webView.onWindowClose = { [weak coordinator = context.coordinator] in
      coordinator?.stop()
    }
    context.coordinator.load(url: url, useLocalServer: useLocalServer, in: webView)
    return webView
  }

  func updateNSView(_ webView: VideoWebView, context: Context) {
    context.coordinator.load(url: url, useLocalServer: useLocalServer, in: webView)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  class Coordinator {
    private var server: LocalServer?
    private var currentURL: URL?
    private weak var webView: WKWebView?

    func load(url: URL, useLocalServer: Bool, in webView: WKWebView) {
      guard url != currentURL else { return }
      currentURL = url
      self.webView = webView

      server?.stop()
      server = nil

      if useLocalServer {
        guard let server = try? LocalServer() else { return }
        self.server = server
        let videoID = url.lastPathComponent
        server.start { [weak webView] port in
          let localURL = URL(string: "http://localhost:\(port)/?v=\(videoID)")!
          webView?.load(URLRequest(url: localURL))
        }
      } else {
        webView.load(URLRequest(url: url))
      }
    }

    func stop() {
      webView?.loadHTMLString("", baseURL: nil)
      server?.stop()
      server = nil
      currentURL = nil
    }

    deinit {
      stop()
    }
  }
}

struct VideoPlayerView: View {
  let request: VideoPlayerRequest

  var body: some View {
    WebView(url: request.url, useLocalServer: request.useLocalServer)
      .frame(minWidth: 480, idealWidth: 960, minHeight: 270, idealHeight: 540)
      .navigationTitle(request.title)
  }
}
