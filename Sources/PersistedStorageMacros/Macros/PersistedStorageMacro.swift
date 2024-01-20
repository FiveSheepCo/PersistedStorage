import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PersistedStorageMacro {}

extension PersistedStorageMacro: MemberAttributeMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, attachedTo declaration: some SwiftSyntax.DeclGroupSyntax, providingAttributesFor member: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AttributeSyntax] {
        guard 
            try VariableInformation(decl: member as! DeclSyntax)?.isAlreadyTracked == false
        else { return [] }
        
        return ["@PersistedStorageTracked"]
    }
}
    
extension PersistedStorageMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let classDecl = declaration as? ClassDeclSyntax else {
            throw PersistedStorageError.message("@PersistedStorage can only be applied to class declarations.")
        }
        
        let className = classDecl.name
        
        var keys: [String] = []
        var reloadCases: [String] = []
        
        for member in classDecl.memberBlock.members {
            guard let info = try VariableInformation(decl: member.decl) else { continue }
            
            let variableName = info.variableName
            let initializer = info.initialValue
            
            keys.append(variableName)
            
            let initialValueSubstitute: String
            switch info.typeKind {
                case .String:
                    initialValueSubstitute = "storage.string(forKey: keyValue)"
                case .Data:
                    initialValueSubstitute = "storage.data(forKey: keyValue)"
                case .Int:
                    initialValueSubstitute = "(storage.object(forKey: keyValue) as? NSNumber)?.intValue"
                case .Double:
                    initialValueSubstitute = "(storage.object(forKey: keyValue) as? NSNumber)?.doubleValue"
                case .Bool:
                    initialValueSubstitute = "(storage.object(forKey: keyValue) as? NSNumber)?.boolValue"
            }
            
            let updateBody = if info.isOptionalWithoutNilInitialValue {
                """
                if isNil() {
                    _\(variableName) = nil
                } else {
                    _\(variableName) = \(initialValueSubstitute) ?? \(initializer)
                }
                """
            } else {
                "_\(variableName) = \(initialValueSubstitute) ?? \(initializer)"
            }
            let caseBody =
            """
                withMutation(keyPath: \\.\(variableName)) {
                    \(updateBody)
                }
            """
            
            reloadCases.append("case .\(variableName): \(caseBody)")
        }
        
        return [
            """
            static let shared = \(className)()
            """,
            """
            private enum Keys: String, CaseIterable {
                case \(raw: keys.joined(separator: ", "))
            }
            """,
            """
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
            """,
            """
            private let storage = NSUbiquitousKeyValueStore.default
            """,
            """
            @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()
            """,
            """
            internal nonisolated func access<Member>(
                keyPath: KeyPath<\(className), Member>
            ) {
                _$observationRegistrar.access(self, keyPath: keyPath)
            }
            """,
            """
            internal nonisolated func withMutation<Member, MutationResult>(
                keyPath: KeyPath<\(className), Member>,
                _ mutation: () throws -> MutationResult
            ) rethrows -> MutationResult {
                try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
            }
            """,
            """
            private func reloadValue(for key: Keys) {
                let keyValue = key.rawValue
                func isNil() -> Bool {
                    storage.string(forKey: keyValue) == PersistedStorageConstants.optionalString
                }
            
                switch key {
                    \(raw: reloadCases.joined(separator: "\n"))
                }
            }
            """,
            """
            private func didChangeExternally(notification: Notification) {
                guard let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
                
                for rawKey in changedKeys {
                    guard let key = Keys(rawValue: rawKey) else { continue }
                    
                    self.reloadValue(for: key)
                }
            }
            """
        ]
    }
}

extension PersistedStorageMacro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        guard let classDecl = declaration as? ClassDeclSyntax else {
            throw PersistedStorageError.message("@PersistedStorage can only be applied to class declarations.")
        }
        
        let className = classDecl.name
        
        return [
            try .init("extension \(className): Observation.Observable {}")
        ]
    }
}
