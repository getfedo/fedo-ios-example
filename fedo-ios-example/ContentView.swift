//
//  ContentView.swift
//  fedo-ios-example
//
//  Created by MABD on 15/09/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack { ModelsListView() }
                .tabItem { Label("Models", systemImage: "sparkles") }
        }
    }
}

#Preview {
    ContentView()
}
