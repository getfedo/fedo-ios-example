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
    /// `ModelFilter.Provider.id`; `nil` = all providers. An id, not a display name, so a refresh
    /// that renames a provider cannot leave the filter matching nothing.
    @State private var selectedProvider: String?
    @State private var showFeedbackSheet = false
    /// The one in-flight load; see `load()`.
    @State private var loadTask: Task<Void, Never>?
    // Fedo buttons only with an API key: the uninitialized SDK's sheet renders blank.
    private let isFedoConfigured = Bundle.main.fedoAPIKey != nil

    var body: some View {
        let providerNames = ModelFilter.providerNames(models ?? [])
        let filtered = ModelFilter.filter(models ?? [], search: searchText, providerID: selectedProvider)

        // ponytail: the list stays mounted in every state so the status views can sit in an .overlay.
        // With zero rows a plain List doesn't bounce, so those states need their own refresh button.
        List {
            // A failed refresh keeps the loaded list; say so in a row instead of the full-screen error.
            if let errorMessage, models?.isEmpty == false {
                Label("Couldn't refresh: \(errorMessage)", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.multicolor)
            }
            ForEach(filtered) { model in
                NavigationLink(value: model) {
                    ModelRow(model: model, provider: providerNames[model.providerID] ?? model.provider)
                }
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
        .toolbar { providerMenu }
        .onChange(of: selectedProvider) { provider in
            // User-level property: last value wins. Report the display name, not the internal id.
            if let provider { Fedo.setUserProperty("favorite_provider", value: providerNames[provider] ?? provider) }
        }
        .presentFedoCreateFeedback(isPresented: $showFeedbackSheet)
    }

    private var providerMenu: some View {
        Menu {
            Picker("Provider", selection: $selectedProvider) {
                Text("All Providers").tag(String?.none)
                ForEach(ModelFilter.providers(models ?? [])) { provider in
                    Text("\(provider.name) (\(provider.count))").tag(String?.some(provider.id))
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
                let buttons = Group {
                    Button("Retry") {
                        self.errorMessage = nil
                        Task { await load() }
                    }
                    if isFedoConfigured {
                        Button("Report a Problem") { showFeedbackSheet = true }
                    }
                }
                // Side by side when they fit, stacked at large Dynamic Type.
                ViewThatFits {
                    HStack { buttons }
                    VStack { buttons }
                }
                .buttonStyle(.bordered)
            }
        } else if models == nil {
            ProgressView()
        } else {
            StatusView(systemImage: "tray", title: "No Models", message: "OpenRouter returned no models.") {
                Button("Refresh") { Task { await load() } }
                    .buttonStyle(.bordered)
            }
        }
    }

    /// Runs one fetch at a time: a new call cancels the in-flight one and queues behind it, so the
    /// newest result always wins and every caller (`.task`, `.refreshable`, Retry) awaits its own.
    private func load() async {
        let previous = loadTask
        previous?.cancel()
        let task = Task {
            await previous?.value
            await fetchModels()
        }
        loadTask = task
        await task.value
    }

    /// Keeps already loaded models when a refresh fails; ignores cancellation.
    private func fetchModels() async {
        do {
            models = try await OpenRouter.fetchModels()
            errorMessage = nil
            // A provider can vanish between refreshes; don't leave a filter that matches nothing.
            if let selectedProvider, !ModelFilter.providers(models ?? []).contains(where: { $0.id == selectedProvider }) {
                self.selectedProvider = nil
            }
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
