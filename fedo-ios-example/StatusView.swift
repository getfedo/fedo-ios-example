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
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            actions
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
