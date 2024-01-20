import Foundation

/// A macro that
@attached(extension, conformances: Observable)
@attached(memberAttribute)
@attached(member, names: named(shared), named(Keys), named(init), named(storage), named(_$observationRegistrar), named(access), named(withMutation), named(reloadValue), named(didChangeExternally))
public macro PersistedStorage() = #externalMacro(module: "PersistedStorageMacros", type: "PersistedStorageMacro")
