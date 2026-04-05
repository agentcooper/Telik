//
//  VideoPlayerWindow.swift
//  Telik

import Network
import SwiftUI
import WebKit

struct VideoPlayerRequest: Codable, Hashable {
  let url: URL
  let title: String
}

class LocalServer {
  private let listener: NWListener
  private let html: String
  private var onReady: ((UInt16) -> Void)?

  init(html: String) throws {
    self.html = html
    let params = NWParameters.tcp
    self.listener = try NWListener(using: params, on: .any)
  }

  func start(onReady: @escaping (UInt16) -> Void) {
    self.onReady = onReady

    listener.newConnectionHandler = { [html] connection in
      connection.start(queue: .main)
      connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { _, _, _, _ in
        let body = Data(html.utf8)
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        let data = Data(response.utf8) + body
        connection.send(content: data, completion: .contentProcessed { _ in
          connection.cancel()
        })
      }
    }

    listener.stateUpdateHandler = { [weak self] state in
      if case .ready = state, let port = self?.listener.port?.rawValue {
        self?.onReady?(port)
        self?.onReady = nil
      }
    }

    listener.start(queue: .main)
  }

  func stop() {
    listener.cancel()
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

  func makeNSView(context: Context) -> VideoWebView {
    let webView = VideoWebView()
    webView.onWindowClose = { [weak coordinator = context.coordinator] in
      coordinator?.stop()
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
    private var server: LocalServer?
    private var currentURL: URL?
    private weak var webView: WKWebView?

    func load(url: URL, in webView: WKWebView) {
      guard url != currentURL else { return }
      currentURL = url
      self.webView = webView

      server?.stop()

      let embedURL = url.absoluteString
      let html = """
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <meta name="referrer" content="strict-origin-when-cross-origin">
      <style>
        body { margin: 0; background: #000; }
        iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
      </style>
      </head>
      <body>
      <iframe
        src="\(embedURL)"
        title="YouTube video player"
        frameborder="0"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        referrerpolicy="strict-origin-when-cross-origin"
        allowfullscreen>
      </iframe>
      </body>
      </html>
      """

      guard let server = try? LocalServer(html: html) else { return }
      self.server = server

      server.start { [weak webView] port in
        let localURL = URL(string: "http://localhost:\(port)")!
        webView?.load(URLRequest(url: localURL))
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
    WebView(url: request.url)
      .frame(minWidth: 480, idealWidth: 960, minHeight: 270, idealHeight: 540)
      .navigationTitle(request.title)
  }
}
