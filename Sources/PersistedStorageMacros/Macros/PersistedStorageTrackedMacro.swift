import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PersistedStorageTrackedMacro {}

extension PersistedStorageTrackedMacro: PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        
        guard let info = try VariableInformation(decl: declaration as! DeclSyntax) else { return [] }
        
        return [
            """
            private var _\(raw: info.variableName): \(raw: info.rawType) = \(raw: info.initialValue)
            """
        ]
    }
}

extension PersistedStorageTrackedMacro: AccessorMacro {
    public static func expansion(of node: SwiftSyntax.AttributeSyntax, providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.AccessorDeclSyntax] {
        guard let info = try VariableInformation(decl: declaration as! DeclSyntax) else { return [] }
        
        let variableName = info.variableName
        
        let key = "Keys.\(variableName).rawValue"
        
        let returnExpression: String
        if case .enumWithRawValue(let originalType) = info.customTypeKind {
            if info.typeIsOptional {
                returnExpression = "_\(variableName).map({ \(originalType)(rawValue: $0) }) ?? \(info.rawInitialValue)"
            } else {
                returnExpression = "\(originalType)(rawValue: _\(variableName)) ?? \(info.rawInitialValue)"
            }
        } else {
            returnExpression = "_\(variableName)"
        }
        
        let storage = if info.isOptionalWithoutNilInitialValue {
            """
            if let newValue {
                storage.set(newValue\(info.nonOptionalRawValueSuffix), forKey: \(key))
            } else {
                storage.set(PersistedStorageConstants.optionalString, forKey: \(key))
            }
            """
        } else {
            "storage.set(newValue\(info.rawValueSuffix), forKey: \(key))"
        }
        
        return [
            """
            get { 
                access(keyPath: \\.\(raw: variableName))
                return \(raw: returnExpression)
            }
            """,
            """
            set {
                withMutation(keyPath: \\.\(raw: variableName)) {
                    _\(raw: variableName) = newValue\(raw: info.rawValueSuffix)
                    \(raw: storage)
                }
            }
            """
        ]
    }
}
