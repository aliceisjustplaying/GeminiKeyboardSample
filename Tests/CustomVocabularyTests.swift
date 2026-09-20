import XCTest
@testable import GeminiVoice

@MainActor
final class CustomVocabularyTests: XCTestCase {
  func testParsingPreservesPhrasesSpellingAndUnicodeWhileRemovingEmptyLinesAndDuplicates() {
    XCTAssertEqual(
      CustomVocabulary.parse("  Voxbench \r\n\r\nTamás Kádár\nC++\nVoxbench\nACME, Inc.\n"),
      ["Voxbench", "Tamás Kádár", "C++", "ACME, Inc."]
    )
  }

  func testSavePersistsAcrossConfigurationInstancesAndClearingRemovesAllTerms() throws {
    let suite = "VocabularyTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let configuration = AppConfiguration(defaults: defaults)
    XCTAssertTrue(configuration.customVocabulary.isEmpty)
    XCTAssertTrue(configuration.saveCustomVocabulary(" Voxbench\nTamás Kádár\nVoxbench "))
    let reloaded = AppConfiguration(defaults: defaults)
    XCTAssertEqual(reloaded.customVocabulary, ["Voxbench", "Tamás Kádár"])
    XCTAssertTrue(reloaded.saveCustomVocabulary(" \n"))
    XCTAssertTrue(AppConfiguration(defaults: defaults).customVocabulary.isEmpty)
  }

  func testOversizedListDoesNotReplaceLastSavedVocabulary() throws {
    let suite = "VocabularyTests.\(UUID().uuidString)"
    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let configuration = AppConfiguration(defaults: defaults)
    let maximum = (1...1_000).map { "Term \($0)" }.joined(separator: "\n")
    XCTAssertTrue(configuration.saveCustomVocabulary(maximum))
    XCTAssertFalse(configuration.saveCustomVocabulary(maximum + "\nOne too many"))
    XCTAssertEqual(AppConfiguration(defaults: defaults).customVocabulary.count, 1_000)
  }

  func testLiveSetupUsesDocumentedVocabularyFieldAndOmitsItWhenEmpty() throws {
    let message = GeminiLiveSpeechSession.setupMessage(
      for: .transcribe, customVocabulary: ["Voxbench", "Tamás Kádár"]
    )
    let setup = try XCTUnwrap(message["setup"] as? [String: Any])
    let transcription = try XCTUnwrap(setup["inputAudioTranscription"] as? [String: Any])
    XCTAssertEqual(transcription["customVocabulary"] as? [String], ["Voxbench", "Tamás Kádár"])
    XCTAssertEqual(transcription["mode"] as? String, "SMART")
    let empty = GeminiLiveSpeechSession.setupMessage(for: .transcribe)
    let emptySetup = try XCTUnwrap(empty["setup"] as? [String: Any])
    let emptyTranscription = try XCTUnwrap(emptySetup["inputAudioTranscription"] as? [String: Any])
    XCTAssertNil(emptyTranscription["customVocabulary"])
  }

  func testLiveTranslationDoesNotSendUnsupportedVocabularyHint() throws {
    let message = GeminiLiveSpeechSession.setupMessage(
      for: .translate(targetLanguageCode: "es"), customVocabulary: ["Voxbench"]
    )
    let setup = try XCTUnwrap(message["setup"] as? [String: Any])
    let transcription = try XCTUnwrap(setup["inputAudioTranscription"] as? [String: Any])
    XCTAssertNil(transcription["customVocabulary"])
  }
}
