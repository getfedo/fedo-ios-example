//
//  StatusView.swift
//  fedo-ios-example
//

import SwiftUI

/// Centered empty/error placeholder (iOS 16 has no `ContentUnavailableView`).
struct StatusView<Actions: View>: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    @ViewBuilder var actions: Actions

    var body: some View {
        // At large Dynamic Type sizes the content can exceed the available height (e.g. inside
        // a List .overlay); fall back to a scroll view instead of letting text truncate.
        ViewThatFits(in: .vertical) {
            content
            ScrollView { content }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var content: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            actions
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}

extension StatusView where Actions == EmptyView {
    init(systemImage: String, title: String, message: String? = nil) {
        self.init(systemImage: systemImage, title: title, message: message) { EmptyView() }
    }
}

#Preview {
    StatusView(systemImage: "wifi.exclamationmark", title: "Couldn't Load Models", message: "The Internet connection appears to be offline.") {
        Button("Retry") {}
            .buttonStyle(.bordered)
    }
}
