import UIKit

final class KeyboardTestTextView: UITextView {
  let voiceKeyboard = KeyboardViewController()
  override var inputViewController: UIInputViewController? { voiceKeyboard }
}

@main
final class TestHost: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    let root = UIViewController()
    let editor = KeyboardTestTextView()
    editor.accessibilityIdentifier = "keyboard-test-editor"
    editor.font = .systemFont(ofSize: 24)
    editor.backgroundColor = .systemBackground
    editor.translatesAutoresizingMaskIntoConstraints = false
    root.view.addSubview(editor)
    NSLayoutConstraint.activate([
      editor.leadingAnchor.constraint(equalTo: root.view.leadingAnchor, constant: 16),
      editor.trailingAnchor.constraint(equalTo: root.view.trailingAnchor, constant: -16),
      editor.topAnchor.constraint(equalTo: root.view.safeAreaLayoutGuide.topAnchor),
      editor.heightAnchor.constraint(equalToConstant: 300)
    ])
    let controls = UIStackView()
    controls.axis = .vertical
    controls.spacing = 8
    controls.translatesAutoresizingMaskIntoConstraints = false
    for (title, action) in [
      ("Toggle recording preview", UIAction { _ in
        let keyboard = editor.voiceKeyboard
        keyboard.pollingTimer?.invalidate()
        keyboard.mode = keyboard.mode == .recording ? .idle : .recording
        keyboard.updateRecordingPresentation(with: keyboard.store.snapshot())
      }),
      ("Insert sample transcript", UIAction { _ in
        editor.voiceKeyboard.insertTranscript("Hello WORLD.")
      })
    ] {
      let button = UIButton(type: .system, primaryAction: action)
      button.setTitle(title, for: .normal)
      controls.addArrangedSubview(button)
    }
    root.view.addSubview(controls)
    NSLayoutConstraint.activate([
      controls.topAnchor.constraint(equalTo: editor.bottomAnchor, constant: 8),
      controls.centerXAnchor.constraint(equalTo: root.view.centerXAnchor)
    ])
    window.rootViewController = root

    window.makeKeyAndVisible()
    self.window = window
    editor.becomeFirstResponder()
    return true
  }
}
