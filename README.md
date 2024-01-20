# PersistedStorage

PersistedStorage is a Swift Package providing persisted iCloud-synced storage for Swift projects using `NSUbiquitousKeyValueStore` internally.

## Description

Apply the `@PersistedStorage` macro to a class containing stored properties, and the class (e.g., `Settings`) will become a singleton accessible by `Settings.shared`. All properties are stored and synced via iCloud Key-Value Storage automatically. The default value is the initializer value you provide.

## Features

- Automatic iCloud synchronization using `NSUbiquitousKeyValueStore`.
- Singleton pattern for easy access (`Settings.shared`).
- Support for various property types, including `String`, `Int`, `Double`, `Bool`, `Data`, optional versions of these and enums with raw values.
- Conforms to the Observation Framework's `Observable` protocol for SwiftUI integration.

## Usage Example

```Swift
enum Test: String {
    case eel, oil
}

@PersistedStorage
class Settings {
    var test: String = "eel"
    var testee: Int = 0
    var douTest: Double = 0
    var datTest: Data? = .init()
    
    @PersistedStorageTracked(customTypeKind: .enumWithRawValue(type: String.self))
    var enumedValue: Test = .eel
    
    @PersistedStorageIgnored
    var ignoredProperty: Bool = false
}
```

How to use the object somewhere in code:
```Swift
Settings.shared.testee = 5
```

## Configuration

The package supports enums with raw values. Use the @PersistedStorageTracked macro with the customTypeKind argument to specify the custom type. For example:

```Swift
@PersistedStorageTracked(customTypeKind: .enumWithRawValue(type: Int.self))
var myEnum: MyEnum = .defaultCase
```

## Contributing

Feel free to contribute to the project through pull requests. We welcome your contributions!
