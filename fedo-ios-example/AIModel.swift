//
//  AIModel.swift
//  fedo-ios-example
//

import Foundation

/// One entry of `GET https://openrouter.ai/api/v1/models` (only the fields the app shows).
nonisolated struct AIModel: Decodable, Identifiable, Hashable, Sendable {
    nonisolated struct Pricing: Decodable, Hashable, Sendable {
        /// USD per token, as a decimal string ("-1" means variable).
        let prompt: String?
        let completion: String?
    }

    nonisolated struct Architecture: Decodable, Hashable, Sendable {
        let inputModalities: [String]?

        enum CodingKeys: String, CodingKey {
            case inputModalities = "input_modalities"
        }
    }

    let id: String
    let name: String
    /// Unix seconds.
    let created: TimeInterval
    let description: String?
    let contextLength: Int?
    let pricing: Pricing?
    let architecture: Architecture?

    enum CodingKeys: String, CodingKey {
        case id, name, created, description, pricing, architecture
        case contextLength = "context_length"
    }

    var createdDate: Date { Date(timeIntervalSince1970: created) }

    /// Display name: "DeepSeek: DeepSeek Pro Latest" -> "DeepSeek"; else id prefix ("~anthropic/x" -> "anthropic").
    var provider: String {
        guard let range = name.range(of: ": ") else { return idPrefix }
        return String(name[..<range.lowerBound])
    }

    /// Group/filter by this; show `provider`. Lowercased id prefix, so "Anthropic: X" and "anthropic/y" match.
    var providerID: String { idPrefix.lowercased() }

    /// "~anthropic/x" -> "anthropic".
    private var idPrefix: String {
        let prefix = id.split(separator: "/").first.map(String.init) ?? id
        return prefix.hasPrefix("~") ? String(prefix.dropFirst()) : prefix
    }

    var shortName: String {
        guard let range = name.range(of: ": ") else { return name }
        return String(name[range.upperBound...])
    }

    var inputPricePerMillion: String { Self.formatPrice(pricing?.prompt) }
    var outputPricePerMillion: String { Self.formatPrice(pricing?.completion) }
    var contextLabel: String? { contextLength.map(Self.formatContext) }

    /// USD-per-token string -> per-million label: "0.00000096" -> "$0.96", "0.000015" -> "$15",
    /// "0" -> "Free", under a cent per million -> "<$0.01",
    /// negative / missing / unparsable -> "Variable".
    static func formatPrice(_ perToken: String?) -> String {
        guard let perToken, let value = Double(perToken), value.isFinite, value >= 0 else { return "Variable" }
        if value == 0 { return "Free" }
        let perMillion = value * 1_000_000
        // Rounding to 4 decimals would print these as "$0"; say "cheap, but not free" instead.
        if perMillion < 0.01 { return "<$0.01" }
        // Whole dollars drop the decimals; otherwise 2...4 fraction digits ("$0.96", "$0.075").
        let isWhole = (perMillion * 10_000).rounded().truncatingRemainder(dividingBy: 10_000) == 0
        let style = FloatingPointFormatStyle<Double>(locale: Locale(identifier: "en_US"))
            .precision(.fractionLength(isWhole ? 0...0 : 2...4))
        return "$" + perMillion.formatted(style)
    }

    /// Decimal units, truncated: 1_048_576 -> "1M", 131_072 -> "131K", 512 -> "512".
    static func formatContext(_ tokens: Int) -> String {
        if tokens >= 1_000_000 { return "\(tokens / 1_000_000)M" }
        if tokens >= 1_000 { return "\(tokens / 1_000)K" }
        return "\(tokens)"
    }
}

/// The models list's provider grouping and search rules. Plain functions so tests can cover them.
nonisolated enum ModelFilter {
    /// One entry of the provider filter menu.
    nonisolated struct Provider: Identifiable, Hashable, Sendable {
        /// Stable across refreshes: the lowest `providerID` of the ids sharing this display name.
        let id: String
        let name: String
        let count: Int
    }

    /// providerID -> display name: `provider` of the group's first "Provider: Model" name, else the id.
    /// Prefix-less names like "Claude Opus 5" inherit "Anthropic" from a sibling model.
    static func providerNames(_ models: [AIModel]) -> [String: String] {
        Dictionary(grouping: models, by: \.providerID).mapValues { group in
            group.first { $0.name.contains(": ") }?.provider ?? group[0].providerID
        }
    }

    /// Menu entries, most models first. Ids sharing a display name merge into one entry
    /// (`meta` + `meta-llama` -> "Meta").
    static func providers(_ models: [AIModel]) -> [Provider] {
        let names = providerNames(models)
        let groups: [String: [AIModel]] = Dictionary(grouping: models) { model in
            names[model.providerID] ?? model.provider
        }
        let providers = groups.map { name, group in
            Provider(id: group.map(\.providerID).min() ?? name, name: name, count: group.count)
        }
        return providers.sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
    }

    /// Models whose name or id contains `search` and, when `providerID` is set, that belong to
    /// its `Provider` entry — matched by display name, so both Meta ids filter together.
    static func filter(_ models: [AIModel], search: String, providerID: String?) -> [AIModel] {
        let names = providerNames(models)
        let providerName = providerID.map { names[$0] ?? $0 }
        let query = search.trimmingCharacters(in: .whitespaces)
        return models.filter { model in
            (providerName == nil || (names[model.providerID] ?? model.provider) == providerName)
                && (query.isEmpty || model.name.localizedCaseInsensitiveContains(query)
                    || model.id.localizedCaseInsensitiveContains(query))
        }
    }
}

nonisolated enum OpenRouter {
    private struct Response: Decodable {
        let data: [AIModel]
    }

    /// Newest first.
    @concurrent static func fetchModels() async throws -> [AIModel] {
        let url = URL(string: "https://openrouter.ai/api/v1/models")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decodeModels(from: data)
    }

    /// Decodes a `{ "data": [...] }` payload, sorted newest first. Split out so tests can use a fixture.
    static func decodeModels(from data: Data) throws -> [AIModel] {
        try JSONDecoder().decode(Response.self, from: data).data.sorted { $0.created > $1.created }
    }
}
