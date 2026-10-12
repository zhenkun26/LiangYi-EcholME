// SPDX-License-Identifier: GPL-3.0-only
// Copyright 2026 EcholME contributors.

import Foundation

enum ExampleTranslation {
  // Hand-authored fixtures for the state-machine tests. Production subtitles
  // come from LocalLexicon. No request, model, credential, or host context.
  private static let chinese = [
    "你好": "hello", "中国": "China", "世界": "world", "谢谢": "thanks",
    "输入法": "input method", "学习": "study", "候选": "candidate",
    "中文": "Chinese", "英文": "English", "两仪": "LiangYi"
  ]
  private static let english = [
    "hello": "你好", "china": "中国", "world": "世界", "thanks": "谢谢",
    "input": "输入", "study": "学习", "candidate": "候选",
    "chinese": "中文", "english": "英文", "liangyi": "两仪"
  ]

  static func results(for snapshot: CandidateSnapshot) -> [CandidateIdentity: String] {
    var result: [CandidateIdentity: String] = [:]
    for candidate in snapshot.candidates {
      let text = candidate.descriptor.primary
      let value = snapshot.direction == .chinese ? chinese[text] : english[text.lowercased()]
      if let value { result[candidate.id] = value }
    }
    return result
  }
}
