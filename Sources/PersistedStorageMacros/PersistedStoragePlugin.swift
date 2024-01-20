import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct PersistedStoragePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PersistedStorageMacro.self, PersistedStorageTrackedMacro.self, PersistedStorageIgnoredMacro.self
    ]
}
