import SwiftUI

struct HistoryRetentionSettings: View {
  @ObservedObject var configuration: AppConfiguration
  @Environment(\.dismiss) private var dismiss
  @State private var days = ""
  @State private var keepForever = true

  private var validDays: Int? {
    guard let value = Int(days), (1...36_500).contains(value) else { return nil }
    return value
  }

  var body: some View {
    Form {
      Section {
        Toggle("Keep forever", isOn: $keepForever)
          .accessibilityIdentifier("history-keep-forever")
        if !keepForever {
          HStack {
            Text("Keep for")
            Spacer()
            TextField("30", text: $days)
              .keyboardType(.numberPad)
              .multilineTextAlignment(.trailing)
              .frame(minWidth: 60, maxWidth: 100)
              .accessibilityLabel("Days to keep history")
              .accessibilityIdentifier("history-retention-days")
            Text("days").foregroundStyle(.secondary)
          }
        }
      } footer: {
        Text(keepForever ? "Saved text stays on this iPhone until you delete it." : "Text older than this is removed when you save and when the app next checks history. Recordings waiting for retry are kept separately.")
      }
      if !keepForever, !days.isEmpty, validDays == nil {
        Text("Enter a whole number from 1 to 36,500.")
          .foregroundStyle(.secondary)
      }
    }
    .navigationTitle("Keep History")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button("Save") {
          guard let value = keepForever ? 0 : validDays else { return }
          configuration.historyRetentionDays = value
          dismiss()
        }
        .disabled(!keepForever && validDays == nil)
        .accessibilityIdentifier("save-history-retention-button")
      }
    }
    .onAppear {
      keepForever = configuration.historyRetentionDays == 0
      days = String(keepForever ? 30 : configuration.historyRetentionDays)
    }
  }
}
