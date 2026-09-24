import SwiftUI

struct VocabularySettingsView: View {
  @ObservedObject var configuration: AppConfiguration
  @State private var isEditing = false
  @State private var draft = ""

  private var terms: [String] { CustomVocabulary.parse(draft) }
  private var exceedsLimit: Bool { terms.count > CustomVocabulary.maximumTerms }

  var body: some View {
    Button {
      draft = configuration.customVocabulary.joined(separator: "\n")
      isEditing = true
    } label: {
      HStack(spacing: 12) {
        Image(systemName: "text.book.closed").foregroundStyle(.blue)
        VStack(alignment: .leading, spacing: 4) {
          Text("Custom vocabulary").font(.headline)
          Text("\(configuration.customVocabulary.count) terms · Names, acronyms and phrases")
            .font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Image(systemName: "chevron.right").foregroundStyle(.secondary)
      }
      .foregroundStyle(.primary)
      .padding(.vertical, 4)
      .background(Color(uiColor: .secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("custom-vocabulary-button")
    .sheet(isPresented: $isEditing) {
      NavigationStack {
        VStack(alignment: .leading, spacing: 14) {
          Text("Add one word or phrase per line, spelled the way you want it written.")
            .font(.subheadline)
          Text("For example: Voxbench, a person's name or a technical term. Keep each on its own line.")
            .font(.caption).foregroundStyle(.secondary)
          TextEditor(text: $draft)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(8)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("Custom vocabulary, one term per line")
            .accessibilityIdentifier("custom-vocabulary-editor")
          Text("\(terms.count) / \(CustomVocabulary.maximumTerms) terms")
            .font(.caption.monospacedDigit())
            .foregroundStyle(exceedsLimit ? Color.red : Color.secondary)
          if exceedsLimit {
            Text("Remove some terms before saving. The limit is 1,000.")
              .font(.caption).foregroundStyle(.red)
          }
          Text("A focused list of up to 100 terms usually works best. Blank lines and exact duplicates are ignored.")
            .font(.caption).foregroundStyle(.secondary)
          Text("Saved on this iPhone and sent to Google when you dictate or retry a saved recording. Changes apply to your next dictation. These hints are not used during live translation.")
            .font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Custom vocabulary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { isEditing = false }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              if configuration.saveCustomVocabulary(draft) { isEditing = false }
            }
            .disabled(exceedsLimit)
            .accessibilityIdentifier("save-custom-vocabulary")
          }
        }
      }
      .interactiveDismissDisabled()
    }
  }
}
