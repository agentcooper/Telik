//
//  TelikTests.swift
//  TelikTests
//
//  Created by Artem Tyurin on 30/05/2022.
//

import XCTest

@testable import Telik

let input = """
1. [вДудь](https://www.youtube.com/channel/UCMCgOm8GZkHp8zJ6l7_hIuA/videos) #Russia #Entertaiment
2. [Systems with JT](https://www.youtube.com/channel/UCrW38UKhlPoApXiuKNghuig/videos) #Programming,#Tech
3. [Сергей Гуриев #1](https://www.youtube.com/channel/UCZ-ix1fUTguJvwj6sxgF-6A/videos)   #Russia
"""

class TelikTests: XCTestCase {
  func testParseSources() async throws {
    let addView = await AddView()
    let result = await addView.parseSources(input: input)
    
    XCTAssertEqual(result, [
      ParseResult(url: URL(string: "https://www.youtube.com/channel/UCMCgOm8GZkHp8zJ6l7_hIuA/videos")!, tags: ["Russia", "Entertaiment"]),
      ParseResult(url: URL(string: "https://www.youtube.com/channel/UCrW38UKhlPoApXiuKNghuig/videos")!, tags: ["Programming", "Tech"]),
      ParseResult(url: URL(string: "https://www.youtube.com/channel/UCZ-ix1fUTguJvwj6sxgF-6A/videos")!, tags: ["Russia"])
    ])
  }
  
  func testExport() async throws {
    let model = await Model()
    
    await model.addSource(Source(id: "foo", type: .channel, title: "Foo", tags: ["A", "B"]))
    await model.addSource(Source(id: "bar", type: .channel, title: "Bar", tags: ["B", "C"]))
    
    let exportWithTags = await model.markdownExport(exportTags: true)
    let exportWithoutTags = await model.markdownExport(exportTags: false)
    
    XCTAssertEqual(exportWithTags, """
1. [Foo](https://www.youtube.com/channel/foo/videos) #A #B
2. [Bar](https://www.youtube.com/channel/bar/videos) #B #C

""")
    
    XCTAssertEqual(exportWithoutTags, """
1. [Foo](https://www.youtube.com/channel/foo/videos)
2. [Bar](https://www.youtube.com/channel/bar/videos)

""")
  }
}
