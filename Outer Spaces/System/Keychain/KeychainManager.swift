import CryptoKit

enum KeychainManager {
    static let serviceName = "OuterSpaces"
    static let licenseStateKey = "LicenseKey"
    static let offlinePermissionKey = "OfflinePermission"
    static let offlinePermissionStartDateKey = "OfflinePermissionStartDate"

    static func saveLicenseStateKey() {
        let key = SymmetricKey(size: .bits256)

        guard let data = "\(key)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: licenseStateKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadLicenseKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: licenseStateKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        print(status)

        if status == errSecSuccess, let data = result as? Data {
            let key = SymmetricKey(data: Data(data))
            return key
        } else {
            saveLicenseStateKey()
            return loadLicenseKey()
        }
    }

    static func saveOfflinePermissionKey() {
        let key = SymmetricKey(size: .bits256)

        guard let data = "\(key)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: offlinePermissionKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadOfflinePermissionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: offlinePermissionKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            let key = SymmetricKey(data: Data(data))
            return key
        } else {
            saveOfflinePermissionKey()
            return loadOfflinePermissionKey()
        }
        return nil
    }
}
