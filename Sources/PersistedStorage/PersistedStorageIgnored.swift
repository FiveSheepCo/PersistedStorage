import Foundation

@attached(peer)
public macro PersistedStorageIgnored() = #externalMacro(module: "PersistedStorageMacros", type: "PersistedStorageIgnoredMacro")
