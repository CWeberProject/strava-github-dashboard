import Foundation

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: TimeInterval
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}
