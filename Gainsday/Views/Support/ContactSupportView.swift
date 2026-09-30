import SwiftUI
import UIKit

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSubject: String?
    @State private var name = ""
    @State private var email = ""
    @State private var orderID = ""
    @State private var message = ""
    @State private var sending = false
    @State private var result: SubmitResult?

    struct SubmitResult { let success: Bool; let text: String }

    static let subjects = [
        ("Bug Report", "ant.fill"),
        ("Feature Request", "lightbulb.fill"),
        ("Billing & Subscription", "creditcard.fill"),
        ("Data Export & Privacy", "externaldrive.fill"),
        ("Account & Sync Issues", "icloud.fill"),
        ("Question / How To", "questionmark.circle.fill"),
        ("Other", "ellipsis.circle.fill")
    ]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@") &&
        selectedSubject != nil &&
        !message.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("What can we help with?") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Self.subjects, id: \.0) { subject, icon in
                        Button {
                            selectedSubject = subject
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: icon)
                                    .foregroundStyle(Theme.orange)
                                Text(subject)
                                    .font(.caption.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedSubject == subject ? Theme.orange.opacity(0.18) : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selectedSubject == subject ? Theme.orange : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            Section("Your details") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Order / Receipt ID (optional)", text: $orderID)
            }
            Section {
                TextField("Describe your issue or idea", text: $message, axis: .vertical)
                    .lineLimit(6...10)
            } footer: {
                Text("We reply within 1-2 business days. App version and device info are attached automatically to help us debug faster.")
            }
            Section {
                Button {
                    send()
                } label: {
                    HStack {
                        Spacer()
                        if sending {
                            ProgressView()
                        } else {
                            Text("Send Message").fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!isValid || sending)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: .init(
            get: { result != nil },
            set: { if !$0 { result = nil } }
        )) {
            Alert(title: Text(result?.success == true ? "Message Sent" : "Something Went Wrong"),
                  message: Text(result?.text ?? ""),
                  dismissButton: .default(Text("OK")) {
                      if result?.success == true { dismiss() }
                  })
        }
    }

    private func send() {
        sending = true
        var request = URLRequest(url: URL(string: "https://msg.calcs.top/api/feedback")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let osVersion = UIDevice.current.systemVersion
        let payload: [String: Any] = [
            "name": name,
            "email": email,
            "subject": selectedSubject ?? "Other",
            "orderId": orderID,
            "message": message,
            "appSlug": "gainsday",
            "appVersion": version,
            "osVersion": "iOS \(osVersion)",
            "deviceModel": UIDevice.current.model
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: request) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                sending = false
                if error == nil, (200..<300).contains(status) {
                    result = SubmitResult(success: true, text: "Thanks! Your message is on its way. We'll reply to \(email).")
                } else {
                    result = SubmitResult(success: false, text: "Could not send right now. Please email us directly at iocompile67692@gmail.com.")
                }
            }
        }.resume()
    }
}

extension ContactSupportView.SubmitResult: Identifiable {
    var id: String { text }
}
