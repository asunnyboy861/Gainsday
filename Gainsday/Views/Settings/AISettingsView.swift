import SwiftUI

struct AISettingsView: View {
    @StateObject private var manager = AIProfileManager.shared
    @ObservedObject private var aiRouter = AIRouter.shared
    @ObservedObject private var quota = QuotaStore.shared
    @State private var selectedProviderID = ProviderProfile.all.first?.id ?? "glm"
    @State private var apiKey = ""
    @State private var baseURL = ""
    @State private var model = ""
    @State private var testResult: String?
    @State private var testing = false
    @State private var showKey = false

    private var selectedProfile: ProviderProfile? {
        ProviderProfile.all.first { $0.id == selectedProviderID }
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "apple.intelligence")
                        .font(.title3)
                        .foregroundStyle(Theme.gold)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Intelligence (Built-in)")
                            .font(.subheadline.weight(.semibold))
                        Text(aiRouter.hasOnDeviceAI()
                             ? "Active. On-device, private, free and unlimited for text coaching."
                             : "Available on iOS 26+. Vision form checks need a cloud key below.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Default Engine")
            } footer: {
                Text("Apple Intelligence handles text coaching on-device when available. Cloud providers below add vision form checks and work on any iOS version.")
            }

            Section {
                ForEach(ProviderProfile.all) { profile in
                    Button {
                        selectedProviderID = profile.id
                        if profile.id != "custom" {
                            baseURL = ""
                            model = ""
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(profile.displayName)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    if profile.supportsVision {
                                        Image(systemName: "eye.fill")
                                            .font(.caption2)
                                            .foregroundStyle(Theme.cyan)
                                    }
                                }
                                Text(profile.note)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            if manager.byoConfig?.providerID == profile.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if selectedProviderID == profile.id {
                                Image(systemName: "circle.inset.filled")
                                    .foregroundStyle(Theme.orange)
                            }
                        }
                    }
                }
            } header: {
                Text("Bring Your Own API Key")
            } footer: {
                Text("Your key is stored in the iOS Keychain on this device only — never in iCloud, never sent anywhere except the provider you choose. With your own key the AI coach is unlimited and billed directly by your provider.")
            }

            Section {
                SecureField("API Key", text: $apiKey)
                if selectedProviderID == "custom" || baseURLFocused {
                    TextField("Base URL", text: $baseURL, prompt: Text(selectedProfile?.defaultBaseURL ?? "https://…/chat/completions"))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else if let profile = selectedProfile {
                    LabeledRow(label: "Endpoint", value: profile.defaultBaseURL)
                }
                if selectedProviderID == "custom" {
                    TextField("Model", text: $model, prompt: Text("e.g. my-model-name"))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else if let profile = selectedProfile {
                    LabeledRow(label: "Model", value: profile.defaultModel)
                }
            } header: {
                Text("Key & Endpoint")
            }

            Section {
                Button {
                    save()
                } label: {
                    Text(apiKey.isEmpty && manager.byoConfig == nil ? "Save Key" : "Save Key" + (manager.byoConfig != nil ? " (overwrite)" : ""))
                }
                .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                Button {
                    test()
                } label: {
                    HStack {
                        Text("Test Connection")
                        if testing { ProgressView() }
                    }
                }
                .disabled(testing)
                if let testResult {
                    Text(testResult)
                        .font(.caption)
                        .foregroundStyle(testResult.hasPrefix("Connection OK") ? .green : .red)
                }
                if manager.byoConfig != nil {
                    Button("Remove Saved Key", role: .destructive) {
                        manager.delete()
                        apiKey = ""
                        testResult = nil
                    }
                }
            } header: {
                Text("Apply")
            } footer: {
                Text("Quota today: \(quota.quotaLabel())")
            }
        }
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadExisting)
    }

    private var baseURLFocused: Bool { selectedProviderID == "custom" }

    private func loadExisting() {
        if let config = manager.byoConfig {
            selectedProviderID = config.providerID
        }
    }

    private func save() {
        manager.save(providerID: selectedProviderID, apiKey: apiKey, baseURL: baseURL, model: model)
        testResult = nil
        apiKey = ""
    }

    private func test() {
        testing = true
        let config: AIKeyConfig?
        if !apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
            let profile = selectedProfile
            config = AIKeyConfig(
                providerID: selectedProviderID,
                apiKey: apiKey.trimmingCharacters(in: .whitespaces),
                baseURL: baseURL.isEmpty ? (profile?.defaultBaseURL ?? "") : baseURL,
                model: model.isEmpty ? (profile?.defaultModel ?? "") : model
            )
        } else {
            config = manager.byoConfig
        }
        guard let config else {
            testing = false
            testResult = "Save or type a key first."
            return
        }
        Task {
            let result = await manager.testConnection(config)
            testResult = result
            testing = false
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
