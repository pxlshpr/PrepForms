import Foundation

enum BiometricSyncStatus: String {
    case notSynced
    case syncing
    case synced
    case lastSyncFailed
    case nextAvailableSynced
}
