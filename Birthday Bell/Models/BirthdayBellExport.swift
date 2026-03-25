import Foundation

// MARK: - Export envelope

struct BirthdayBellExport: Codable {
    let version: Int
    let exportedAt: Date
    let appBundleID: String
    let friends: [Friend]
}

// MARK: - Import support types

enum ImportStrategy {
    case mergeNew
    case mergeAndReplace
    case replaceAll
}

struct ImportResult: Identifiable {
    let id = UUID()
    let incoming: [Friend]
    let newFriends: [Friend]
    let conflictFriends: [Friend]
    let totalExisting: Int
}

enum ImportError: LocalizedError {
    case invalidFormat
    case wrongApp
    case unsupportedVersion

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The file could not be read. It may be corrupted or not a valid Birthday Bell file."
        case .wrongApp:
            return "This file was not created by Birthday Bell."
        case .unsupportedVersion:
            return "This file was created by a newer version of Birthday Bell. Please update the app."
        }
    }
}
