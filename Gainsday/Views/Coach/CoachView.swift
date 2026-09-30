import SwiftUI
import UIKit
import PhotosUI

struct CameraPicker: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CoachView: View {
    @Environment(\.modelContext) private var context
    @ObservedObject private var quota = QuotaStore.shared
    @State private var exercise: Exercise?
    @State private var showExercisePicker = false
    @State private var showCamera = false
    @State private var showLibraryPicker = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var annotatedImage: UIImage?
    @State private var poseWarning: String?
    @State private var phase: Phase = .idle
    @State private var feedback: FormFeedback?
    @State private var providerLabel = ""
    @State private var errorMessage: String?
    @State private var showPaywall = false

    enum Phase: Equatable {
        case idle, checking, analyzing, done, failed
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    quotaBanner
                    exerciseCard
                    captureCard
                    if let warning = poseWarning { warningCard(warning) }
                    if case .checking = phase { checkingCard }
                    if case .analyzing = phase { analyzingCard }
                    if let fb = feedback { feedbackCard(fb) }
                    if let error = errorMessage { errorCard(error) }
                    disclaimer
                }
                .padding(.horizontal)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.charcoal)
            .navigationTitle("AI Form Coach")
            .sheet(isPresented: $showExercisePicker) {
                ExercisePicker { exercise = $0 }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    handleImage(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: libraryItem) { _, item in
                guard let item else { return }
                libraryItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        handleImage(image)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var quotaBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.gold)
            Text(quota.quotaLabel())
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if !AIConfiguration.hasAPIKey {
                Button("Unlimited") { showPaywall = true }
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .clipShape(Capsule())
    }

    private var exerciseCard: some View {
        Button {
            showExercisePicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Exercise")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(exercise?.name ?? "Choose a lift")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var captureCard: some View {
        VStack(spacing: 12) {
            if let display = annotatedImage ?? capturedImage {
                Image(uiImage: display)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                HStack(spacing: 12) {
                    Button("Retake") {
                        capturedImage = nil
                        annotatedImage = nil
                        feedback = nil
                        errorMessage = nil
                        poseWarning = nil
                        phase = .idle
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.orange)
                Text("Snap one photo from the side at your sticking point.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.orange)
                .disabled(exercise == nil)
                PhotosPicker(selection: $libraryItem, matching: .images) {
                    Label("Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .disabled(exercise == nil)
            }
            if exercise == nil {
                Text("Pick an exercise first so the coach knows what to look for.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var checkingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Checking body position…")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var analyzingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Coach is analyzing your form…")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func warningCard(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(text)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func feedbackCard(_ fb: FormFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Coach Feedback", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                Spacer()
                Text(providerLabel.isEmpty ? "AI" : providerLabel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.orange.opacity(0.18)))
                    .foregroundStyle(Theme.orange)
            }
            if !fb.good.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(fb.good, id: \.self) { g in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(g).font(.subheadline)
                        }
                    }
                }
            }
            if !fb.fix.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(fb.fix, id: \.self) { f in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill").foregroundStyle(Theme.orange)
                            Text(f).font(.subheadline)
                        }
                    }
                }
            }
            if !fb.cue.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remember this cue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("“\(fb.cue)”")
                        .font(Theme.rounded(20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Theme.charcoal.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if !fb.risk.isEmpty, fb.risk.lowercased() != "unknown" {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "shield.lefthalf.filled").foregroundStyle(.red)
                    Text(fb.risk).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private func errorCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .foregroundStyle(.red)
                Text("Coach unavailable")
                    .font(.headline)
            }
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            NavigationLink("Open AI Settings") {
                AISettingsView()
            }
            .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var disclaimer: some View {
        Text("Form feedback is AI-generated guidance for healthy adults, not medical advice. Stop immediately if you feel pain.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
    }

    private func handleImage(_ image: UIImage) {
        capturedImage = image
        annotatedImage = nil
        feedback = nil
        errorMessage = nil
        poseWarning = nil
        phase = .checking
        let check = FormCheckPreprocessor.validate(image)
        guard check.isValid else {
            poseWarning = check.message
            phase = .failed
            return
        }
        annotatedImage = FormCheckPreprocessor.annotatedImage(image, joints: check.joints)
        guard let jpeg = FormCheckPreprocessor.compressed(image), let ex = exercise else {
            phase = .failed
            errorMessage = AIServiceError.notConfigured.errorDescription
            return
        }
        phase = .analyzing
        Task {
            do {
                let (result, _) = try await AIRouter.shared.analyzeForm(frameJPEG: jpeg, exerciseName: ex.name)
                providerLabel = AIRouter.shared.lastProviderLabel
                feedback = result
                phase = .done
            } catch {
                phase = .failed
                errorMessage = offlineMessage(for: error)
            }
        }
    }

    private func offlineMessage(for error: Error) -> String {
        if let aiError = error as? AIServiceError {
            switch aiError {
            case .notConfigured:
                return "No AI backend is connected. Use Apple Intelligence on iOS 26+, add your own API key in Settings > AI Coach, or subscribe for cloud quota."
            case .quotaExhausted:
                return "Your monthly cloud quota is used up. Add your own API key in Settings for unlimited coach sessions."
            default:
                break
            }
        }
        return "Couldn't reach the AI coach. Check your connection and try again."
    }
}
