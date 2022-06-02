//
//  Markdown.swift
//  Telik
//
//  Created by Artem Tyurin on 26/05/2022.
//

import Foundation

func markdownLink(_ text: String, _ url: String) -> String {
  return "[\(text)](\(url))"
}
