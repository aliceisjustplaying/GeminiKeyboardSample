import XCTest

@testable import GeminiVoice

final class TranscriptFormatterTests: XCTestCase {
  func testLowercaseInsertionIncludesNamesAcronymsAndUnicodeWithoutChangingPunctuation() {
    XCTAssertEqual(
      TranscriptFormatter.textForInsertion("Transcript: I met Tamás at NASA!", contextBefore: "Hello", lowercase: true),
      " i met tamás at nasa!"
    )
    XCTAssertEqual(
      TranscriptFormatter.textForInsertion("I met Tamás at NASA!", contextBefore: nil, lowercase: false),
      "I met Tamás at NASA!"
    )
    XCTAssertEqual(TranscriptFormatter.textForInsertion("  ", contextBefore: "Hello", lowercase: true), "")
  }

  func testTranslationCleanerUnwrapsKnownJSONEnvelopesOnly() {
    XCTAssertEqual(
      TranscriptFormatter.cleanedTranslation("{\"source_Text\":\"Hello\"}"),
      "Hello"
    )
    XCTAssertEqual(
      TranscriptFormatter.cleanedTranslation("{\"translated_text\":\"Hello\"}"),
      "Hello"
    )
    XCTAssertEqual(
      TranscriptFormatter.cleanedTranslation("{\"actual\":\"dictated JSON\"}"),
      "{\"actual\":\"dictated JSON\"}"
    )
  }

  func testCleanerRemovesCommonModelWrappers() {
    XCTAssertEqual(
      TranscriptFormatter.cleaned("  Transcript: \"Meet me at five.\"  "),
      "Meet me at five."
    )
    XCTAssertEqual(
      TranscriptFormatter.cleaned("```\nA fenced transcript.\n```"),
      "A fenced transcript."
    )
  }

  func testInsertionAddsSpaceAfterExistingWord() {
    XCTAssertEqual(
      TranscriptFormatter.textForInsertion("next thought", contextBefore: "Existing"),
      " next thought"
    )
    XCTAssertEqual(
      TranscriptFormatter.textForInsertion("next thought", contextBefore: "Existing "),
      "next thought"
    )
    XCTAssertEqual(
      TranscriptFormatter.textForInsertion(".", contextBefore: "Existing"),
      "."
    )
  }
}
