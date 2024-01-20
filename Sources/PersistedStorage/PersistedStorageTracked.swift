import Foundation

@attached(accessor, names: named(init), named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro PersistedStorageTracked(
    customTypeKind: CustomTypeKind? = nil
) = #externalMacro(module: "PersistedStorageMacros", type: "PersistedStorageTrackedMacro")

public enum CustomTypeKind {
    case enumWithRawValue(type: Any.Type)
}
