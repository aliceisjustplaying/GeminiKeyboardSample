import CryptoKit
import Darwin
import UIKit

extension KeyboardViewController {
  var lowercaseDictation: Bool {
    UserDefaults.standard.bool(forKey: LocalKey.lowercaseDictation)
  }

  @objc func lowercaseTapped() {
    UserDefaults.standard.set(!lowercaseDictation, forKey: LocalKey.lowercaseDictation)
    configureLowercaseButton()
    UISelectionFeedbackGenerator().selectionChanged()
  }

  func configureLowercaseButton() {
    let enabled = lowercaseDictation
    var configuration = UIButton.Configuration.filled()
    configuration.title = "abc"
    configuration.cornerStyle = .capsule
    configuration.contentInsets = .zero
    configuration.baseBackgroundColor = enabled ? .systemBlue : .tertiarySystemFill
    configuration.baseForegroundColor = enabled ? .white : Self.keyForegroundColor
    lowercaseButton.configuration = configuration
    lowercaseButton.accessibilityLabel = "Lowercase dictation"
    lowercaseButton.accessibilityValue = enabled ? "On" : "Off"
    lowercaseButton.accessibilityHint = "Lowercases all dictated text when inserted, including names and acronyms. Tap to toggle."
    lowercaseButton.accessibilityIdentifier = "keyboard-lowercase-button"
    lowercaseButton.accessibilityTraits = enabled ? [.button, .selected] : [.button]
  }

  @objc func cancelTapped() {
    guard let activeRequestID,
      let activeDictationAction
    else { return }

    switch mode {
    case .openingHost:
      // Supersede any unhandled start command and remove a cold-launch
      // request before the containing app can send audio to Gemini.
      store.clearLaunchAuthorization(for: activeRequestID)
      store.issue(
        .cancel,
        requestID: activeRequestID,
        dictationAction: activeDictationAction
      )
      clearTrackedRequest()
      hostLaunchFailureExpiresAt = nil
      mode = .idle
    case .recording, .transcribing:
      store.issue(
        .cancel,
        requestID: activeRequestID,
        dictationAction: activeDictationAction
      )
      mode = .cancelling
      persistTrackedRequest()
    case .idle, .cancelling, .resultWaiting:
      return
    }
    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    refreshFromSharedState()
  }

  @objc func insertLatestTapped() {
    guard let pendingTranscript else { return }
    insertTranscript(pendingTranscript, kind: pendingResultKind ?? .dictation)
    self.pendingTranscript = nil
    if let pendingResultSequence {
      markResultConsumed(sequence: pendingResultSequence)
    }
    self.pendingResultSequence = nil
    self.pendingResultKind = nil
    setInsertLatestVisible(false)
    mode = .idle
    refreshFromSharedState()
  }

  func setInsertLatestVisible(_ isVisible: Bool) {
    insertLatestButton.isHidden = !isVisible
    updateActionVisibility()
    updateKeyboardHeight()
  }

  func markResultConsumed(sequence: Int) {
    store.acknowledgeResult(sequence: sequence)
    UserDefaults.standard.set(sequence, forKey: LocalKey.consumedResultSequence)
    lastObservedResultSequence = max(lastObservedResultSequence, sequence)
  }
}
