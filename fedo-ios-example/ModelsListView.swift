//
//  ModelsListView.swift
//  fedo-ios-example
//

import FedoKit
import SwiftUI

struct ModelsListView: View {
    /// `nil` until the first successful load.
    @State private var models: [AIModel]?
    @State private var errorMessage: String?
    @State private var searchText = ""
    /// Provider display name; `nil` = all providers.
    @State private var selectedProvider: String?
    @State private var showFeedbackSheet = false
    // Fedo buttons only with an API key: the uninitialized SDK's sheet renders blank.
    private let isFedoConfigured = Bundle.main.fedoAPIKey != nil

    var body: some View {
        // providerID -> display name: `provider` of the group's first "Provider: Model" name, else the id.
        // Merges ids sharing a name (`meta` + `meta-llama` -> "Meta"); prefix-less names like "Claude Opus 5" get "Anthropic".
        let providerNames = Dictionary(grouping: models ?? [], by: \.providerID).mapValues { group in
            group.first { $0.name.contains(": ") }?.provider ?? group[0].providerID
        }
        let filtered = filteredModels(providerNames)

        // ponytail: the list stays mounted in every state so pull-to-refresh also works on empty/error.
        List(filtered) { model in
            NavigationLink(value: model) {
                ModelRow(model: model, provider: providerNames[model.providerID] ?? model.provider)
            }
        }
        .listStyle(.plain)
        .overlay { status(noResults: filtered.isEmpty) }
        .navigationTitle("Latest Models")
        .navigationDestination(for: AIModel.self) { model in
            ModelDetailView(model: model, provider: providerNames[model.providerID] ?? model.provider)
        }
        .task {
            // `.task` re-runs on every appear (e.g. popping back); only fetch the first time.
            if models == nil { await load() }
        }
        .refreshable { await load() }
        .searchable(text: $searchText)
        .toolbar { providerMenu(providerNames) }
        .onChange(of: selectedProvider) { provider in
            // User-level property: last value wins.
            if let provider { Fedo.setUserProperty("favorite_provider", value: provider) }
        }
        .presentCreateFeedback(isPresented: $showFeedbackSheet)
    }

    private func filteredModels(_ providerNames: [String: String]) -> [AIModel] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        return (models ?? []).filter { model in
            (selectedProvider == nil || providerNames[model.providerID] == selectedProvider)
                && (query.isEmpty || model.name.localizedCaseInsensitiveContains(query)
                    || model.id.localizedCaseInsensitiveContains(query))
        }
    }

    private func providerMenu(_ providerNames: [String: String]) -> some View {
        // Display name -> model count, most models first.
        let counts = (models ?? []).reduce(into: [String: Int]()) { counts, model in
            counts[providerNames[model.providerID] ?? model.provider, default: 0] += 1
        }
        .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }

        return Menu {
            Picker("Provider", selection: $selectedProvider) {
                Text("All Providers").tag(String?.none)
                ForEach(counts, id: \.key) { provider in
                    Text("\(provider.key) (\(provider.value))").tag(String?.some(provider.key))
                }
            }
        } label: {
            Label("Filter by provider", systemImage: selectedProvider == nil
                ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }

    @ViewBuilder private func status(noResults: Bool) -> some View {
        if models?.isEmpty == false {
            if noResults {
                StatusView(systemImage: "magnifyingglass", title: "No Results", message: "No models match your search or provider filter.") {
                    if isFedoConfigured {
                        Button("Missing a model? Request it") { showFeedbackSheet = true }
                            .buttonStyle(.bordered)
                    }
                }
            }
        } else if let errorMessage {
            StatusView(systemImage: "wifi.exclamationmark", title: "Couldn't Load Models", message: errorMessage) {
                HStack {
                    Button("Retry") {
                        self.errorMessage = nil
                        Task { await load() }
                    }
                    if isFedoConfigured {
                        Button("Report a Problem") { showFeedbackSheet = true }
                    }
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
    let provider: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.shortName)
                .font(.headline)
            Text("\(provider) · \(model.createdDate, format: .relative(presentation: .named))")
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
