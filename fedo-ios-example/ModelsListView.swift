//
//  ModelsListView.swift
//  fedo-ios-example
//

import SwiftUI

struct ModelsListView: View {
    /// `nil` until the first successful load.
    @State private var models: [AIModel]?
    @State private var errorMessage: String?

    var body: some View {
        // ponytail: the list stays mounted in every state so pull-to-refresh also works on empty/error.
        List(models ?? []) { model in
            NavigationLink(value: model) {
                ModelRow(model: model)
            }
        }
        .listStyle(.plain)
        .overlay { status }
        .navigationTitle("Latest Models")
        .navigationDestination(for: AIModel.self) { model in
            ModelDetailView(model: model)
        }
        .task {
            // `.task` re-runs on every appear (e.g. popping back); only fetch the first time.
            if models == nil { await load() }
        }
        .refreshable { await load() }
    }

    @ViewBuilder private var status: some View {
        if models?.isEmpty == false {
            EmptyView()
        } else if let errorMessage {
            StatusView(systemImage: "wifi.exclamationmark", title: "Couldn't Load Models", message: errorMessage) {
                Button("Retry") {
                    self.errorMessage = nil
                    Task { await load() }
                }
                .buttonStyle(.bordered)
            }
        } else if models == nil {
            ProgressView()
        } else {
            StatusView(systemImage: "tray", title: "No Models", message: "OpenRouter returned no models. Pull to refresh.")
        }
    }

    /// Keeps already loaded models when a refresh fails; ignores cancellation.
    private func load() async {
        do {
            models = try await OpenRouter.fetchModels()
            errorMessage = nil
        } catch is CancellationError {
        } catch let error as URLError where error.code == .cancelled {
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ModelRow: View {
    let model: AIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.shortName)
                .font(.headline)
            Text("\(model.provider) · \(model.createdDate, format: .relative(presentation: .named))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(details)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var details: String {
        let price = "\(model.inputPricePerMillion) / 1M in"
        guard let context = model.contextLabel else { return price }
        return "\(context) context · \(price)"
    }
}

#Preview {
    NavigationStack { ModelsListView() }
}
