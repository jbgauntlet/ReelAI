

import Foundation
import Security

let SERVICE = "com.test.service"

func saveToKeychain(value: String, forKey key: String, service: String) -> Bool {
    let data = value.data(using: .utf8)!

    // Create a query to store the value
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecValueData as String: data
    ]

    // Add the value to Keychain
    let status = SecItemAdd(query as CFDictionary, nil)

    // If the item already exists, update it
    if status == errSecDuplicateItem {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        return status == errSecSuccess
    }

    return status == errSecSuccess
}

func retrieveFromKeychain(forKey key: String, service: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess, let data = item as? Data else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

func deleteFromKeychain(forKey key: String, service: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: key
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
}
