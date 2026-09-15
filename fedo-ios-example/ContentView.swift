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
            NavigationStack { FeedbacksView() }
                .tabItem { Label("Roadmap", systemImage: "lightbulb") }
        }
    }
}

#Preview {
    ContentView()
}
