//
//  ModelDetailView.swift
//  fedo-ios-example
//

import SwiftUI

struct ModelDetailView: View {
    let model: AIModel
    /// Display name resolved by the list (`model.provider` can be the lowercase id prefix).
    let provider: String

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.shortName)
                        .font(.title2.bold())
                    Text(provider)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Pricing") {
                LabeledContent("Input per 1M", value: model.inputPricePerMillion)
                LabeledContent("Output per 1M", value: model.outputPricePerMillion)
            }

            Section("Details") {
                LabeledContent("Context", value: model.contextLabel.map { "\($0) tokens" } ?? "Unknown")
                LabeledContent("Released", value: model.createdDate.formatted(.dateTime.day().month().year()))
                if !modalities.isEmpty {
                    LabeledContent("Input modalities", value: modalities)
                }
                LabeledContent("Model ID") {
                    HStack {
                        Text(model.id)
                            .font(.callout.monospaced())
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = model.id
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Copy Model ID")
                    }
                }
            }

            if let description = model.description, !description.isEmpty {
                Section("Description") {
                    Text(description)
                }
            }
        }
        .navigationTitle(model.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var modalities: String {
        (model.architecture?.inputModalities ?? []).map(\.capitalized).joined(separator: ", ")
    }
}

#Preview {
    let json = """
    {"data": [{"id": "anthropic/claude-sonnet-4.5", "name": "Anthropic: Claude Sonnet 4.5", "created": 1758844800,
      "description": "Anthropic's most capable Sonnet model, tuned for coding and long-running agent workflows.",
      "context_length": 1000000, "pricing": {"prompt": "0.000003", "completion": "0.000015"},
      "architecture": {"input_modalities": ["text", "image", "file"]}}]}
    """
    let model = try! OpenRouter.decodeModels(from: Data(json.utf8))[0]
    NavigationStack { ModelDetailView(model: model, provider: model.provider) }
}
