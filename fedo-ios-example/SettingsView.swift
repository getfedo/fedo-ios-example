//
//  SettingsView.swift
//  fedo-ios-example
//
//  Created by MABD on 15/09/2026.
//

import FedoKit
import SwiftUI

struct SettingsView: View {
    @AppStorage("demoUserName") private var userName = ""
    @AppStorage("demoUserEmail") private var userEmail = ""
    @State private var name = ""
    @State private var email = ""

    private let isFedoConfigured = Bundle.main.fedoAPIKey != nil
    private let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"

    var body: some View {
        Form {
            Section {
                LabeledContent("Status", value: isFedoConfigured ? "Initialized" : "No API key")
            } header: {
                Text("Fedo SDK")
            } footer: {
                if !isFedoConfigured {
                    Text("Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig, add your Fedo API key, and rebuild.")
                }
            }

            Section {
                if userEmail.isEmpty {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Sign In", action: signIn)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@"))
                } else {
                    LabeledContent("Name", value: userName)
                    LabeledContent("Email", value: userEmail)
                    Button("Sign Out", role: .destructive, action: signOut)
                }
            } header: {
                Text("Demo account")
            } footer: {
                Text("Demo only, no backend. Feedback, votes and comments you made as a guest move to this account when you sign in. Signing out starts a new guest.")
            }

            Section("About") {
                Link("Fedo Docs", destination: URL(string: "https://docs.getfedo.com/next/guide/getting-started/")!)
                Link("getfedo.com", destination: URL(string: "https://getfedo.com")!)
                Link("Model data by OpenRouter", destination: URL(string: "https://openrouter.ai")!)
                LabeledContent("Version", value: appVersion)
            }
        }
        .navigationTitle("Settings")
    }

    private func signIn() {
        let name = name.trimmingCharacters(in: .whitespaces)
        let email = email.trimmingCharacters(in: .whitespaces)
        // ponytail: demo ID derived from email; real apps pass their own backend user ID.
        Fedo.setUserID("demo-" + email.lowercased())
        Fedo.setUserDisplayName(name)
        Fedo.setUserEmail(email)
        userName = name
        userEmail = email
        self.name = ""
        self.email = ""
    }

    private func signOut() {
        Fedo.logout()
        userName = ""
        userEmail = ""
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
