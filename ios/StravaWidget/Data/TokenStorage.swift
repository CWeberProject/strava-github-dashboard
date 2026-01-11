import Foundation
import Security

final class TokenStorage {
    static let shared = TokenStorage()

    private let service = Constants.keychainService

    private init() {}

    var accessToken: String? {
        get { getString(forKey: "access_token") }
        set { setString(newValue, forKey: "access_token") }
    }

    var refreshToken: String? {
        get { getString(forKey: "refresh_token") }
        set { setString(newValue, forKey: "refresh_token") }
    }

    var expiresAt: TimeInterval {
        get { getDouble(forKey: "expires_at") }
        set { setDouble(newValue, forKey: "expires_at") }
    }

    var isLoggedIn: Bool {
        accessToken != nil && refreshToken != nil
    }

    var isTokenExpired: Bool {
        Date().timeIntervalSince1970 >= expiresAt
    }

    func saveTokens(accessToken: String, refreshToken: String, expiresAt: TimeInterval) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    func saveTokens(from response: TokenResponse) {
        saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        expiresAt = 0
    }

    // MARK: - Keychain Helpers

    private func setString(_ value: String?, forKey key: String) {
        if let value = value {
            let data = Data(value.utf8)
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]

            let attributes: [String: Any] = [
                kSecValueData as String: data
            ]

            let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

            if status == errSecItemNotFound {
                var newItem = query
                newItem[kSecValueData as String] = data
                newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
                SecItemAdd(newItem as CFDictionary, nil)
            }
        } else {
            deleteItem(forKey: key)
        }
    }

    private func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func setDouble(_ value: TimeInterval, forKey key: String) {
        setString(String(value), forKey: key)
    }

    private func getDouble(forKey key: String) -> TimeInterval {
        guard let string = getString(forKey: key) else { return 0 }
        return TimeInterval(string) ?? 0
    }

    private func deleteItem(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
