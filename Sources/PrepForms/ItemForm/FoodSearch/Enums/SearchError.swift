import Foundation
import PrepDataTypes

public enum SearchError: Error {
    case cancelled(SearchScope)
    case unhandledError(SearchScope, Error)
}
