import Foundation

enum PersistedStorageError: Error, CustomStringConvertible {
    case message(String)
    
    var description: String {
        switch self {
            case .message(let text):
                return text
        }
    }
}