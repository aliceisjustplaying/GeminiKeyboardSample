import Foundation

/// Preserve spelling and order while ignoring empty lines and exact duplicates.
enum CustomVocabulary {
  static let maximumTerms = 1_000

  static func parse(_ text: String) -> [String] {
    var seen = Set<String>()
    return text.components(separatedBy: .newlines).compactMap { line in
      let term = line.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !term.isEmpty, seen.insert(term).inserted else { return nil }
      return term
    }
  }
}
