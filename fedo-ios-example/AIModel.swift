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
    /// "0" -> "Free", negative / missing / unparsable -> "Variable".
    static func formatPrice(_ perToken: String?) -> String {
        guard let perToken, let value = Double(perToken), value.isFinite, value >= 0 else { return "Variable" }
        if value == 0 { return "Free" }
        let perMillion = value * 1_000_000
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
