import KeyboardKit
import SwiftUI

/// A small local picker, independent of KeyboardKit Pro's emoji keyboard.
struct EmojiPicker: View {
  let actionHandler: KeyboardActionHandler
  private let emojis = "😀 😃 😄 😁 😅 😂 🤣 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😋 😛 🤪 😎 🤩 🥳 😏 😒 😔 😢 😭 😤 😡 🤔 🤭 🫢 🫠 😴 🤯 😱 🥺 🙄 💀 👻 🤖 👍 👎 👏 🙌 🤝 🙏 💪 👀 ❤️ 🧡 💛 💚 💙 💜 🖤 🤍 💔 💕 ✨ 🔥 🎉 ✅ ❌ 💯 🚀 🌈 ☀️ 🌙 🐈 🐕 🌻 🍕 ☕ 🍺 🎂 🎁".split(separator: " ").map(String.init)

  var body: some View {
    VStack(spacing: 4) {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 42))], spacing: 4) {
          ForEach(emojis, id: \.self) { emoji in
            Button(emoji) { actionHandler.handle(.release, on: .character(emoji)) }
              .font(.system(size: 28))
              .frame(minWidth: 42, minHeight: 42)
              .accessibilityLabel(emoji)
          }
        }
      }
      HStack {
        Button("ABC") { actionHandler.handle(.press, on: .keyboardType(.alphabetic)) }
          .accessibilityLabel("Back to letters")
        Spacer()
        Button { actionHandler.handle(.press, on: .backspace) } label: {
          Image(systemName: "delete.left")
        }
        .accessibilityLabel("Delete")
      }
      .padding(.horizontal)
      .frame(height: 36)
    }
    .frame(height: 220)
  }
}
