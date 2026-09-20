//
//  AIModelTests.swift
//  fedo-ios-exampleTests
//

import Foundation
import Testing
@testable import fedo_ios_example

/// Trimmed `GET https://openrouter.ai/api/v1/models` payload, deliberately not sorted by `created`.
private let fixture = Data("""
{
  "data": [
    {
      "id": "meta-llama/llama-4-scout:free",
      "canonical_slug": "meta-llama/llama-4-scout-17b-16e-instruct",
      "name": "Meta: Llama 4 Scout (free)",
      "created": 1743881519,
      "description": "Llama 4 Scout 17B Instruct (16E) is a mixture-of-experts language model.",
      "context_length": 131072,
      "architecture": {"modality": "text+image->text", "input_modalities": ["text", "image"], "output_modalities": ["text"], "tokenizer": "Llama4"},
      "pricing": {"prompt": "0", "completion": "0", "request": "0", "image": "0"},
      "top_provider": {"context_length": 131072, "max_completion_tokens": null, "is_moderated": false},
      "supported_parameters": ["max_tokens", "temperature", "tools"]
    },
    {
      "id": "deepseek/deepseek-v4-pro",
      "name": "DeepSeek: DeepSeek V4 Pro",
      "created": 1788000000,
      "description": "DeepSeek V4 Pro is a large mixture-of-experts reasoning model.",
      "context_length": 1048576,
      "architecture": {"modality": "text->text", "input_modalities": ["text"], "output_modalities": ["text"]},
      "pricing": {"prompt": "0.00000096", "completion": "0.0000038"}
    },
    {
      "id": "openrouter/auto",
      "name": "Auto Router",
      "created": 1699401600,
      "description": null,
      "context_length": null
    },
    {
      "id": "~anthropic/claude-sonnet-latest",
      "name": "Anthropic: Claude Sonnet Latest",
      "created": 1789000000,
      "description": "Always points to the latest Claude Sonnet model.",
      "context_length": 200000,
      "architecture": {"input_modalities": ["text", "image", "file"]},
      "pricing": {"prompt": "-1", "completion": "-1"}
    },
    {
      "id": "meta/llama-guard-4",
      "name": "Meta: Llama Guard 4",
      "created": 1750000000,
      "context_length": 163840,
      "pricing": {"prompt": "0.00000002", "completion": "0.00000002"}
    },
    {
      "id": "anthropic/claude-opus-5",
      "name": "Claude Opus 5",
      "created": 1790000000,
      "context_length": 400000,
      "pricing": {"prompt": "0.000005", "completion": "0.000025"}
    },
    {
      "id": "~moonshotai/kimi-latest",
      "name": "Kimi Latest",
      "created": 1787000000,
      "context_length": 262144,
      "pricing": {"prompt": "0.000000075", "completion": "0.000015"}
    }
  ]
}
""".utf8)

struct AIModelTests {
    let models: [AIModel]

    init() throws {
        models = try OpenRouter.decodeModels(from: fixture)
    }

    @Test func decodesNewestFirst() throws {
        #expect(models.map(\.id) == [
            "anthropic/claude-opus-5",
            "~anthropic/claude-sonnet-latest",
            "deepseek/deepseek-v4-pro",
            "~moonshotai/kimi-latest",
            "meta/llama-guard-4",
            "meta-llama/llama-4-scout:free",
            "openrouter/auto",
        ])
        let deepseek = try #require(models.first { $0.id == "deepseek/deepseek-v4-pro" })
        #expect(deepseek.contextLength == 1_048_576)
        #expect(deepseek.pricing?.prompt == "0.00000096")
        #expect(deepseek.architecture?.inputModalities == ["text"])
        #expect(deepseek.inputPricePerMillion == "$0.96")
        #expect(deepseek.outputPricePerMillion == "$3.80")
        #expect(deepseek.contextLabel == "1M")
    }

    @Test func optionalFieldsTolerateNullAndMissing() throws {
        let auto = try #require(models.first { $0.id == "openrouter/auto" })
        #expect(auto.description == nil)
        #expect(auto.contextLength == nil)
        #expect(auto.contextLabel == nil)
        #expect(auto.pricing == nil)
        #expect(auto.architecture == nil)
        #expect(auto.inputPricePerMillion == "Variable")

        let kimi = try #require(models.first { $0.id == "~moonshotai/kimi-latest" })
        #expect(kimi.description == nil)
        #expect(kimi.architecture == nil)
    }

    @Test(arguments: [
        ("0.00000096", "$0.96"),
        ("0.000000075", "$0.075"),
        ("0.000015", "$15"),
        // Below a cent per million: 4-decimal rounding would print "$0".
        ("0.000000000005", "<$0.01"),
        ("0", "Free"),
        ("-1", "Variable"),
        ("abc", "Variable"),
        (nil, "Variable"),
    ] as [(String?, String)])
    func formatsPrice(perToken: String?, expected: String) {
        #expect(AIModel.formatPrice(perToken) == expected)
    }

    @Test(arguments: [
        (1_048_576, "1M"),
        (2_000_000, "2M"),
        (200_000, "200K"),
        (131_072, "131K"),
        (32_768, "32K"),
        (512, "512"),
    ])
    func formatsContext(tokens: Int, expected: String) {
        #expect(AIModel.formatContext(tokens) == expected)
    }

    @Test(arguments: [
        // "Provider: Name" -> provider from the name; providerID is always the lowercased id prefix.
        ("deepseek/deepseek-v4-pro", "DeepSeek", "deepseek", "DeepSeek V4 Pro"),
        ("meta-llama/llama-4-scout:free", "Meta", "meta-llama", "Llama 4 Scout (free)"),
        ("meta/llama-guard-4", "Meta", "meta", "Llama Guard 4"),
        ("~anthropic/claude-sonnet-latest", "Anthropic", "anthropic", "Claude Sonnet Latest"),
        // No colon in the name -> id-prefix fallback, "~" stripped.
        ("anthropic/claude-opus-5", "anthropic", "anthropic", "Claude Opus 5"),
        ("openrouter/auto", "openrouter", "openrouter", "Auto Router"),
        ("~moonshotai/kimi-latest", "moonshotai", "moonshotai", "Kimi Latest"),
    ])
    func providerAndShortName(id: String, provider: String, providerID: String, shortName: String) throws {
        let model = try #require(models.first { $0.id == id })
        #expect(model.provider == provider)
        #expect(model.providerID == providerID)
        #expect(model.shortName == shortName)
    }

    @Test func providerNamesMergeIDsAndFillInMissingPrefixes() {
        let names = ModelFilter.providerNames(models)
        // Two ids, one display name.
        #expect(names["meta"] == "Meta")
        #expect(names["meta-llama"] == "Meta")
        // "Claude Opus 5" carries no "Provider: " prefix; the group takes the name from a sibling.
        #expect(names["anthropic"] == "Anthropic")
        // Nothing in the group has a prefix -> the id stands in.
        #expect(names["openrouter"] == "openrouter")
    }

    @Test func providerMenuEntriesMergeAndSortByCount() {
        let providers = ModelFilter.providers(models)
        #expect(providers == [
            ModelFilter.Provider(id: "anthropic", name: "Anthropic", count: 2),
            // One "Meta" entry for both ids, keyed by the lowest of them.
            ModelFilter.Provider(id: "meta", name: "Meta", count: 2),
            ModelFilter.Provider(id: "deepseek", name: "DeepSeek", count: 1),
            ModelFilter.Provider(id: "moonshotai", name: "moonshotai", count: 1),
            ModelFilter.Provider(id: "openrouter", name: "openrouter", count: 1),
        ])
    }

    @Test func filtersBySearchAndProviderTogether() {
        #expect(ModelFilter.filter(models, search: "", providerID: nil) == models)
        // The "meta" entry covers both Meta ids.
        #expect(ModelFilter.filter(models, search: "", providerID: "meta").map(\.id)
            == ["meta/llama-guard-4", "meta-llama/llama-4-scout:free"])
        // Search is trimmed, case-insensitive, and matches the id as well as the name.
        #expect(ModelFilter.filter(models, search: "  LLAMA ", providerID: nil).map(\.id)
            == ["meta/llama-guard-4", "meta-llama/llama-4-scout:free"])
        #expect(ModelFilter.filter(models, search: "guard", providerID: "meta").map(\.id) == ["meta/llama-guard-4"])
        // Both conditions must hold.
        #expect(ModelFilter.filter(models, search: "guard", providerID: "deepseek").isEmpty)
        // An id that is gone from the data matches nothing, so the view clears it after a load.
        #expect(ModelFilter.filter(models, search: "", providerID: "mistralai").isEmpty)
    }
}
