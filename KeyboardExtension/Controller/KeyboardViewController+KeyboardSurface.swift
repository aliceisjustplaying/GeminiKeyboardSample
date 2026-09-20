import KeyboardKit
import SwiftUI

extension KeyboardViewController {
  func configureKeyboardKit() {
    setupKeyboardKit(for: KeyboardApp(
      name: "Gemini Voice",
      appGroupId: VoiceAppGroup.identifier
    )) { result in
      if case .failure(let error) = result {
        NSLog("KEYBOARDKIT_SETUP_FAILED %@", error.localizedDescription)
      }
    }
  }

  func configureKeyboardView() {
    state.feedbackContext.settings.isAudioFeedbackEnabled = false
    buildInterface()
    let controls = rootStack
    let presentation = voicePresentation
    setupKeyboardView { controller in
      GeminiKeyboardView(
        services: controller.services,
        controls: controls,
        presentation: presentation
      )
    }
  }
}

@MainActor
final class VoiceKeyboardPresentation: ObservableObject {
  @Published var controlsHeight: CGFloat = 45
  @Published var isRecording = false
}

private struct VoiceControlsView: UIViewRepresentable {
  let controls: UIView
  func makeUIView(context: Context) -> UIView { controls }
  func updateUIView(_ uiView: UIView, context: Context) {}
}

private struct GeminiKeyboardView: View {
  let services: KeyboardServices
  let controls: UIView
  @ObservedObject var presentation: VoiceKeyboardPresentation

  var body: some View {
    Group {
      if presentation.isRecording {
        voiceControls
      } else {
        KeyboardView(
          services: services,
          buttonContent: { $0.view },
          buttonView: { $0.view },
          collapsedView: { $0.view },
          emojiKeyboard: { _ in EmojiPicker(actionHandler: services.actionHandler) },
          toolbar: { _ in voiceControls }
        )
      }
    }
    .background(Color(uiColor: KeyboardViewController.keyboardBackgroundColor))
  }

  private var voiceControls: some View {
    VoiceControlsView(controls: controls)
      .frame(height: presentation.controlsHeight)
  }
}
