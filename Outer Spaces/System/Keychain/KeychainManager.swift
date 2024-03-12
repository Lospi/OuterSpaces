enum KeychainManager {
    static let serviceName = "OuterSpacesTrialStateService"
    static let licenseStateKey = "LicenseState"
    static let offlinePermissionKey = "OfflinePermission"
    static let offlinePermissionStartDateKey = "OfflinePermissionStartDate"

    static func saveLicenseState(_ state: Bool) {
        guard let data = "\(state)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: licenseStateKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadLicenseState() -> Bool? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: licenseStateKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            if let stateString = String(data: data, encoding: .utf8), let state = Bool(stateString) {
                return state
            }
        }

        return nil
    }

    static func deleteLicenseState() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: licenseStateKey
        ]

        SecItemDelete(query as CFDictionary)
    }

    static func saveOfflinePermission(_ state: Bool) {
        guard let data = "\(state)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: offlinePermissionKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadOfflinePermission() -> Bool? {
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
            if let stateString = String(data: data, encoding: .utf8), let state = Bool(stateString) {
                return state
            }
        }

        return nil
    }

    static func saveOfflinePermissionStartDate(_ date: Date) {
        guard let data = "\(date.timeIntervalSince1970)".data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: offlinePermissionStartDateKey,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadOfflinePermissionStartDate() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: offlinePermissionStartDateKey,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue!
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            if let timeIntervalString = String(data: data, encoding: .utf8), let timeInterval = TimeInterval(timeIntervalString) {
                return Date(timeIntervalSince1970: timeInterval)
            }
        }

        return nil
    }
}
