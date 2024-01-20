import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct VariableInformation {
    enum TypeKind: String {
        case String, Int, Double, Bool, Data
    }
    enum CustomTypeKind {
        case enumWithRawValue(originalType: String)
    }
    
    let variableName: String
    let rawInitialValue: String
    let initialValue: String
    let rawType: String
    let typeKind: TypeKind
    let customTypeKind: CustomTypeKind?
    let isOptionalWithoutNilInitialValue: Bool
    let isAlreadyTracked: Bool
    
    let typeIsOptional: Bool
    let nonOptionalRawValueSuffix: String
    let rawValueSuffix: String
    
    init?(decl: DeclSyntax) throws {
        guard
            let varDecl = decl.as(VariableDeclSyntax.self),
            !varDecl.attributes.contains(where: { $0.trimmedDescription == "@PersistedStorageIgnored" }),
            varDecl.bindings.first?.accessorBlock == nil
        else { return nil }
        
        guard
            let binding = varDecl.bindings.first, varDecl.bindings.count == 1,
            let variableName = binding.pattern.as(IdentifierPatternSyntax.self)?.description,
            let rawInitializer = binding.initializer?.value.trimmedDescription,
            let rawType = binding.typeAnnotation?.type
        else {
            throw PersistedStorageError.message("Classes with @PersistedStorage can only contain single binding variables that have to have an initial value.")
        }
        
        self.typeIsOptional = rawType.is(OptionalTypeSyntax.self)
        
        guard let rawTypeString = rawType.as(IdentifierTypeSyntax.self)?.name.trimmedDescription ?? rawType.as(OptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?.name.trimmedDescription else {
            throw PersistedStorageError.message("Properties that are @PersistedStorageTracked can only be a type identifier or an optional type identifier.")
        }
        
        let replacementRawType: String?
        if
            let node = try varDecl.attributes.first(where: { $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "PersistedStorageTracked" })?.as(AttributeSyntax.self),
            let argumentList = node.arguments?.as(LabeledExprListSyntax.self),
            let first = argumentList.first?.as(LabeledExprSyntax.self),
            let expression = first.expression.as(FunctionCallExprSyntax.self),
            let firstArgument = expression.arguments.as(LabeledExprListSyntax.self)?.first?.as(LabeledExprSyntax.self),
            let type = firstArgument.expression.as(MemberAccessExprSyntax.self)?.base
        {
            replacementRawType = type.trimmedDescription
            self.customTypeKind = .enumWithRawValue(originalType: rawTypeString)
            self.rawValueSuffix = "\(typeIsOptional ? "?" : "").rawValue"
            self.nonOptionalRawValueSuffix = ".rawValue"
        } else {
            replacementRawType = nil
            self.customTypeKind = nil
            self.rawValueSuffix = ""
            self.nonOptionalRawValueSuffix = ""
        }
        
        let actualType = replacementRawType ?? rawTypeString
        guard let typeKind = TypeKind(rawValue: actualType) else {
            throw PersistedStorageError.message("Properties that are @PersistedStorageTracked can only be of types `String`, `Int`, `Double`, `Bool`, `Data` or optional versions of these. If \(variableName) is implicitly @PersistedStorageTracked, you can add the @PersistedStorageIgnored macro to not track it. You can also add a `customTypeKind` argument to the macro.")
        }
        
        let initialIsNil = rawInitializer == "nil"
        
        self.rawType = if let replacementRawType {
            if typeIsOptional {
                replacementRawType + "?"
            } else {
                replacementRawType
            }
        } else {
            rawType.trimmedDescription
        }
        self.typeKind = typeKind
        
        self.variableName = variableName
        self.isOptionalWithoutNilInitialValue = typeIsOptional && !initialIsNil
        self.isAlreadyTracked = varDecl.attributes.contains(where: { $0.trimmedDescription.starts(with: "@PersistedStorageTracked") })
        
        self.rawInitialValue = rawInitializer
        self.initialValue = if
            !initialIsNil,
            case .enumWithRawValue(let originalType) = customTypeKind
        {
            "\(originalType)\(rawInitializer).rawValue"
        } else {
            rawInitializer
        }
    }
}
