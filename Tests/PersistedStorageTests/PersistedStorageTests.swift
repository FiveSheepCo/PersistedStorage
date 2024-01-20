import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(PersistedStorageMacros)
import PersistedStorageMacros

let testMacros: [String: Macro.Type] = [
    "PersistedStorage": PersistedStorageMacro.self,
]
#endif

final class PersistedStorageTests: XCTestCase {
    func testMacro() throws {
        #if canImport(PersistedStorageMacros)
        assertMacroExpansion(
            """
            @PersistedStorage
            class Settings {
                var test: String = "eel"
                var testee: Int = 0
                var douTest: Double = 0
                var datTest: Data? = .init()
                
                @PersistedStorageIgnored
                var ignoredEel: Bool = false
            }
            """,
            expandedSource: """
            class Settings {
                @PersistedStorageTracked
                var test: String = "eel"
                @PersistedStorageTracked
                var testee: Int = 0
                @PersistedStorageTracked
                var douTest: Double = 0
                @PersistedStorageTracked
                var datTest: Data? = .init()
                
                @PersistedStorageIgnored
                var ignoredEel: Bool = false
            
                static let shared = Settings ()
            
                private enum Keys: String, CaseIterable {
                    case test, testee, douTest, datTest
                }
            
                private init() {
                    for key in Keys.allCases {
                        reloadValue(for: key)
                    }
            
                    NotificationCenter.default.addObserver(
                        forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                        object: storage,
                        queue: .main,
                        using: didChangeExternally
                    )
                }
            
                private let storage = NSUbiquitousKeyValueStore.default
            
                @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()
            
                internal nonisolated func access<Member>(
                    keyPath: KeyPath<Settings , Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }
            
                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<Settings , Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }
            
                private func reloadValue(for key: Keys) {
                    let keyValue = key.rawValue
                    func isNil() -> Bool {
                        storage.string(forKey: keyValue) == PersistedStorageConstants.optionalString
                    }
            
                    switch key {
                        case .test:
                        withMutation(keyPath: \\.test) {
                                _test = storage.string(forKey: keyValue) ?? "eel"
                            }
                    case .testee:
                        withMutation(keyPath: \\.testee) {
                                _testee = (storage.object(forKey: keyValue) as? NSNumber)?.intValue ?? 0
                            }
                    case .douTest:
                        withMutation(keyPath: \\.douTest) {
                                _douTest = (storage.object(forKey: keyValue) as? NSNumber)?.doubleValue ?? 0
                            }
                    case .datTest:
                        withMutation(keyPath: \\.datTest) {
                                if isNil() {
                             _datTest = nil
                            } else {
                                _datTest = storage.data(forKey: keyValue) ?? .init()
                            }
                        }
                    }
                }
            
                private func didChangeExternally(notification: Notification) {
                    guard let changedKeys = notification.userInfo? [NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
                        return
                    }
                    
                    for rawKey in changedKeys {
                        guard let key = Keys(rawValue: rawKey) else { continue }
                        
                        self.reloadValue(for: key)
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
