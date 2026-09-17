//
//  ContentView.swift
//  fedo-ios-example
//
//  Created by MABD on 15/09/2026.
//

import FedoKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { ModelsListView() }
                .tabItem { Label("Models", systemImage: "sparkles") }
            // FeedbacksView pushes its own screens, so it needs its own NavigationStack in a tab.
            NavigationStack {
                // The uninitialized SDK renders blank, so the app explains setup itself.
                if Bundle.main.fedoAPIKey == nil {
                    StatusView(systemImage: "key", title: "Fedo Not Configured", message: "Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig, add your Fedo API key, and rebuild.")
                        .navigationTitle("Roadmap")
                } else {
                    FedoFeedbackView()
                }
            }
            .tabItem { Label("Roadmap", systemImage: "lightbulb") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
}
