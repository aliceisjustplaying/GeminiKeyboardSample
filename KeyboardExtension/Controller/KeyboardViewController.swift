import CryptoKit
import Darwin
import UIKit
import KeyboardKit

final class KeyboardViewController: KeyboardInputViewController {
  enum LocalKey {
    static let lowercaseDictation = "keyboard.lowercase-dictation"
    static let consumedResultSequence = "keyboard.consumed-result-sequence"
    static let activeRequestID = "keyboard.active-request-id"
    static let activeRequestAction = "keyboard.active-request-action"
    static let activeRequestCreatedAt = "keyboard.active-request-created-at"
    static let activeRequestIsCancelling = "keyboard.active-request-is-cancelling"
    static let activeDocumentIdentifier = "keyboard.active-document-identifier"
    static let contextBeforeFingerprint = "keyboard.active-context-before-fingerprint"
    static let contextAfterFingerprint = "keyboard.active-context-after-fingerprint"
    static let awaitsKeyboardReactivation = "keyboard.active-awaits-reactivation"
    static let legacyContextBefore = "keyboard.active-context-before"
    static let legacyContextAfter = "keyboard.active-context-after"
  }

  enum DictationMode {
    case idle
    case openingHost
    case recording
    case cancelling
    case transcribing
    case resultWaiting
  }

  let store = SharedRelayStore()
  let sharedPreferences = UserDefaults(suiteName: VoiceAppGroup.identifier) ?? .standard
  var pollingTimer: Timer?
  var mode: DictationMode = .idle
  var keyboardIsVisible = false

  var activeRequestID: String?
  var activeDocumentIdentifier: UUID?
  var contextBeforeFingerprintAtRequest: String?
  var contextAfterFingerprintAtRequest: String?
  var lastObservedResultSequence = 0
  var pendingTranscript: String?
  var pendingResultSequence: Int?
  var pendingResultKind: RelayResultKind?
  var activeDictationAction: RelayDictationAction?
  var trackedRequestCreatedAt: Date?
  var hostLaunchFailureExpiresAt: Date?
  var hostLaunchAttemptedForRequestID: String?
  var hostResolutionPendingForRequestID: String?
  var hostResolutionGeneration = 0
  var recentArbiterHosts: [Int32: (bundleIdentifier: String, observedAt: Date)] = [:]
  #if GEMINI_PERSONAL_DEVICE
    static var keyboardArbiterEnabledOverrideInstalled = false
  #endif
  var awaitsKeyboardReactivation = false
  var keyboardReactivationIsReady = false
  var keyboardActivationGeneration = 0
  var keyboardSettleWorkItem: DispatchWorkItem?

  let rootStack = UIStackView()
  let voicePresentation = VoiceKeyboardPresentation()
  let recordingPanel = UIView()
  let waveformView = LiveWaveformView()
  let recordingTitleLabel = UILabel()
  let brandMarkView = KeyboardBrandMarkView()
  let processingStatusStack = UIStackView()
  let processingIndicator = UIActivityIndicatorView(style: .medium)
  let processingLabel = UILabel()
  let timerLabel = UILabel()
  let lowercaseButton = KeyboardButton(type: .system)
  let microphoneButton = KeyboardButton(type: .system)
  let translateButton = KeyboardButton(type: .system)
  let cancelButton = KeyboardButton(type: .system)
  let insertLatestButton = KeyboardButton(type: .system)

  override func viewWillSetupKeyboardKit() { configureKeyboardKit() }

  override func viewWillSetupKeyboardView() { configureKeyboardView() }

  override func viewDidLoad() {
    super.viewDidLoad()
    hasDictationKey = false
    lastObservedResultSequence = UserDefaults.standard.integer(
      forKey: LocalKey.consumedResultSequence
    )
    restoreTrackedRequest()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    keyboardActivationGeneration += 1
    keyboardIsVisible = true
    if awaitsKeyboardReactivation {
      keyboardReactivationIsReady = false
    }
    refreshFromSharedState()
    startPolling()
    scheduleKeyboardSettleIfNeeded(after: 0.22)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    keyboardActivationGeneration += 1
    hostResolutionGeneration += 1
    hostResolutionPendingForRequestID = nil
    recentArbiterHosts.removeAll()
    keyboardSettleWorkItem?.cancel()
    keyboardSettleWorkItem = nil
    keyboardIsVisible = false
    keyboardReactivationIsReady = false
    processingIndicator.stopAnimating()
    pollingTimer?.invalidate()
    pollingTimer = nil
  }

  static let keyboardBackgroundColor = UIColor { traits in
    traits.userInterfaceStyle == .dark
      ? UIColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1)
      : UIColor(red: 0.89, green: 0.89, blue: 0.91, alpha: 1)
  }

  static let keyForegroundColor = UIColor { traits in
    traits.userInterfaceStyle == .dark ? .white : .black
  }

  override func textDidChange(_ textInput: UITextInput?) {
    super.textDidChange(textInput)
    // Host apps can replace the text proxy just after the keyboard appears.
    // Restart the short settle window so the insertion anchor is captured
    // from the final proxy rather than its transition placeholder.
    scheduleKeyboardSettleIfNeeded(after: 0.16)
    refreshFromSharedState()
  }

  func scheduleKeyboardSettleIfNeeded(after delay: TimeInterval) {
    guard awaitsKeyboardReactivation, keyboardIsVisible else { return }
    let activationGeneration = keyboardActivationGeneration
    // Any proxy/context change starts a fresh quiet window. Do not let a
    // previously completed settle authorize Start while the host is still
    // replacing its text input connection.
    keyboardReactivationIsReady = false
    keyboardSettleWorkItem?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      guard let self,
        self.keyboardActivationGeneration == activationGeneration,
        self.keyboardIsVisible,
        self.view.window != nil,
        self.awaitsKeyboardReactivation
      else {
        return
      }
      self.keyboardSettleWorkItem = nil
      self.keyboardReactivationIsReady = true
      self.refreshFromSharedState()
    }
    keyboardSettleWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
  }
}
