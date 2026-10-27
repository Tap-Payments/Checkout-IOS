//
//  LocalKeys.swift
//  SPMExample
//
//  Your own sandbox keys, kept out of the repo. Debug simulator builds read keys.local.json at the
//  repo root (it is gitignored), and Settings > Saved Keys switches between them. See
//  keys.local.example.json for the format.
//

import Foundation

struct LocalKey: Decodable {
    let name: String
    let publicKey: String
    let merchantId: String?
}

enum LocalKeys {
    /// Read each time so edits to the file show up the next time Settings opens.
    static var all: [LocalKey] {
        #if DEBUG && targetEnvironment(simulator)
        // A simulator app can read files on the Mac; this file is SPMExample/SPMExample/LocalKeys.swift.
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("keys.local.json")
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([LocalKey].self, from: data)) ?? []
        #else
        return []
        #endif
    }
}
