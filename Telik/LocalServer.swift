//
//  LocalServer.swift
//  Telik
//

import Foundation
import Network

class LocalServer {
  private let listener: NWListener
  private var onReady: ((UInt16) -> Void)?

  init() throws {
    let params = NWParameters.tcp
    self.listener = try NWListener(using: params, on: .any)
  }

  private static func iframeHTML(videoID: String?) -> String {
    let embedURL: String
    if let videoID, videoID.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil {
      embedURL = "https://www.youtube-nocookie.com/embed/\(videoID)?rel=0&autoplay=1"
    } else {
      embedURL = "about:blank"
    }
    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="referrer" content="strict-origin-when-cross-origin">
    <style>
      body { margin: 0; background: #000; }
      iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
    </style>
    </head>
    <body>
    <iframe
      src="\(embedURL)"
      title="YouTube video player"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen></iframe>
    </body>
    </html>
    """
  }

  private static func parseVideoID(from data: Data) -> String? {
    guard let request = String(data: data, encoding: .utf8) else { return nil }
    guard let firstLine = request.split(separator: "\r\n", maxSplits: 1).first else { return nil }
    let parts = firstLine.split(separator: " ")
    guard parts.count >= 2 else { return nil }
    let path = String(parts[1])
    guard let components = URLComponents(string: "http://localhost\(path)") else { return nil }
    return components.queryItems?.first(where: { $0.name == "v" })?.value
  }

  func start(onReady: @escaping (UInt16) -> Void) {
    self.onReady = onReady

    listener.newConnectionHandler = { connection in
      connection.start(queue: .main)
      connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
        let videoID = data.flatMap { LocalServer.parseVideoID(from: $0) }
        let html = LocalServer.iframeHTML(videoID: videoID)
        let body = Data(html.utf8)
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        let responseData = Data(response.utf8) + body
        connection.send(content: responseData, completion: .contentProcessed { _ in
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
