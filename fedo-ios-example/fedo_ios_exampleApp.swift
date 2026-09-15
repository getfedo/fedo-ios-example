//
//  fedo_ios_exampleApp.swift
//  fedo-ios-example
//
//  Created by MABD on 15/09/2026.
//

import FedoKit
import SwiftUI

@main
struct fedo_ios_exampleApp: App {
    init() {
        guard let apiKey = Bundle.main.fedoAPIKey else {
            print("[ModelPulse] Fedo not initialized: no API key. Copy Config/Secrets.example.xcconfig to Config/Secrets.xcconfig and set FEDO_API_KEY.")
            return
        }
        #if DEBUG
        Fedo.initialize(apiKey: apiKey, config: FedoConfig(logLevel: .debug))
        #else
        Fedo.initialize(apiKey: apiKey, config: FedoConfig(logLevel: .none))
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

extension Bundle {
    /// Fedo API key from Info.plist (`FedoAPIKey`, set by Config/Secrets.xcconfig); nil when missing or empty.
    var fedoAPIKey: String? {
        let key = (object(forInfoDictionaryKey: "FedoAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }
}
