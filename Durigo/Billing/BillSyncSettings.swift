//
//  BillSyncSettings.swift
//  Durigo
//
//  Sheet for entering the bill upload API token. Stored in Keychain.
//

import SwiftUI

struct BillSyncSettings: View {
    @Environment(\.dismiss) private var dismiss
    @State private var token: String = KeychainHelper.load(.billUploadToken) ?? ""
    @State private var showingSaved: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Bearer Token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("billUploadTokenField")
                } header: {
                    Text("Bill Upload Token")
                } footer: {
                    Text("Required to sync bills to the server. Get this from the .env on the Pi (BILL_UPLOAD_API_TOKEN).")
                }

                Section {
                    LabeledContent("Server", value: Config.shared.serverURL)
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("Configured in Config.swift via plist (prod / dev / local).")
                }

                if showingSaved {
                    Section {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Sync Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if token.isEmpty {
                            KeychainHelper.delete(.billUploadToken)
                        } else {
                            KeychainHelper.save(token, for: .billUploadToken)
                        }
                        showingSaved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            dismiss()
                        }
                    }
                    .disabled(token == (KeychainHelper.load(.billUploadToken) ?? ""))
                    .accessibilityIdentifier("saveTokenButton")
                }
            }
        }
    }
}

#Preview {
    BillSyncSettings()
}
